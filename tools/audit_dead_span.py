#!/usr/bin/env python3
"""audit_dead_span.py — is a byte span of a 68000 opcode view PROVEN DEAD: nothing can execute it and nothing can
read it? (14z-216, GitHub #294: the per-frame palette table's 16-bit word must reach a jump to the ported routine, so
it needs six dead bytes within PRG:0x022DEC-0x032DEB; promoted from build/agent216/rc294/dead/.)

  python3 tools/audit_dead_span.py <opcodes.bin> <data.bin> --span 024024-024029
        [--code 0-100000[,lo-hi...]] [--allow-table BASE:ROW] [--plant jsr|long|table] [--expect live]

A span is judged DEAD only when all four hold, each computed over-approximately (a false reference can only HIDE a
dead byte, never invent one):
  A  no instruction decoded at EVERY even address of the code ranges (not one linear path) names any span address
     in its operand text (branch targets, abs.w/abs.l, capstone-resolved PC-relative EAs, #immediates);
  C  no 32-bit big-endian value at ANY 2-aligned offset of EITHER full view equals a span address;
  T  no table gives a span address: every `(d8,PC,Xn)` EA and every lea/pea/movea.l/move.l #imm operand inside the
     code ranges is a table base B; its words B+0.. (the opcode view for a PC-indexed base, BOTH views for a base
     loaded into a register, which CPS-2 reads through the data view) are read as offsets while B+o stays below the
     lowest forward target seen (the jump-table extent rule, at most 0x400 bytes), and its longs likewise; a row
     that gives a span address is a reference unless named by --allow-table (the port's own row);
  L  the span is FENCED by live code: the instruction ending exactly where the span starts is reached and is an
     unconditional transfer (bra/jmp/rts/rte/rtr — no fall-through), and the byte after the span is reached. Reached
     = recursive descent from the 256 vectors, every in-range long of both views, and every table row (rule T),
     following Bcc/DBcc both ways, BSR/JSR target + fall-through, BRA/JMP target. A fenced span cannot be the tail
     of a data table without that table overlapping live code.
What it cannot see, stated: an address computed arithmetically at run time from no constant (base + a computed
offset with neither the base nor the result appearing anywhere), and a reader that reaches the span through a
table whose base is formed that way. The runtime bound (execution counts over the legacy corpus) is a separate
instrument (build/agent216/rc294/dead/exec_bound.sh); MAME read taps are blind to ROM fetches (RH-15).

--plant (controls; the image is changed IN MEMORY only, then every check re-runs over it):
  jsr    a `jsr <span start>.l` written at the first even address of the LAST code range's top 0x10 bytes -> A fires
  long   the span start as a long written at data-view offset len-0x10 -> C fires
  table  a `move.w (d8,PC,D0.w),D1` and a two-row word table whose row 0 gives the span start, planted 0x200 bytes
         past the span (a 16-bit row reaches only +-32K) -> T fires
--expect live: exit 0 only when the verdict is NOT DEAD (the known-live control span).
Prints addresses, counts and mnemonics only — never ROM bytes (CLAUDE.md rule 7).
"""
import argparse, hashlib, re, sys

HEXRE = re.compile(r'(-?)\$([0-9a-f]+)')
PCIDX = re.compile(r'\$([0-9a-f]+)\(pc, [ad]\d')


def md():
    import capstone
    return capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)


def dec(m, op, a):
    return next(m.disasm(bytes(op[a:a + 10]), a, count=1), None)


def sext(w):
    return w - 0x10000 if w & 0x8000 else w


def judge(op, da, slo, shi, ranges, allow):
    m = md()
    incode = lambda a: any(lo <= a < hi for lo, hi in ranges) and not a & 1
    span = set(range(slo, shi + 1))
    A, C, T = [], [], []
    bases = {}
    for lo, hi in ranges:
        for a in range(lo & ~1, hi, 2):
            i = dec(m, op, a)
            if not i:
                continue
            for neg, h in HEXRE.findall(i.op_str):
                if not neg and int(h, 16) in span:
                    A.append((a, f"{i.mnemonic} {i.op_str}"))
            p = PCIDX.search(i.op_str)
            if p:
                bases.setdefault(int(p.group(1), 16), [a, set()])[1].add('op')
            elif i.mnemonic in ('lea', 'pea', 'movea.l') or (i.mnemonic == 'move.l' and i.op_str.startswith('#')):
                h = re.match(r'#?\$([0-9a-f]+)', i.op_str)
                if h and incode(int(h.group(1), 16)):
                    # a base loaded into a register is read through it: a DATA-view read on CPS-2; the opcode view
                    # too, in case the same base is also read PC-relatively
                    bases.setdefault(int(h.group(1), 16), [a, set()])[1].update(('op', 'data'))
    for name, v in (('op', op), ('data', da)):
        for a in range(0, len(v) - 3, 2):
            if int.from_bytes(v[a:a + 4], 'big') in span:
                C.append((name, a))
    rows = {}   # base -> list of in-extent targets (for reachability)
    for B, (site, views) in bases.items():
        tg = []
        for vn in sorted(views):
            v = op if vn == 'op' else da
            lim = B + 0x400
            for o in range(0, 0x400, 2):
                if B + o >= lim:
                    break
                t = B + sext(int.from_bytes(v[B + o:B + o + 2], 'big'))
                x = int.from_bytes(v[B + o:B + o + 4], 'big')
                for cand in (t, x):
                    if cand in span and (B, o // 2) not in allow:
                        T.append((B, site, o // 2, cand, vn))
                    if incode(cand):
                        tg.append(cand)
                if t > B and incode(t):
                    lim = min(lim, t)
        rows[B] = tg
    # L: recursive descent
    entries = set()
    for a in range(0, 0x400, 4):
        x = int.from_bytes(da[a:a + 4], 'big')
        if incode(x):
            entries.add(x)
    for v in (op, da):
        for a in range(0, len(v) - 3, 2):
            x = int.from_bytes(v[a:a + 4], 'big')
            if incode(x):
                entries.add(x)
    for tg in rows.values():
        entries.update(tg)
    code, term, work = {}, set(), list(entries)
    while work:
        a = work.pop()
        while incode(a) and a not in code:
            i = dec(m, op, a)
            if not i:
                break
            code[a] = i.size
            mn, s = i.mnemonic, i.op_str
            tg = [int(h, 16) for neg, h in HEXRE.findall(s) if not neg]
            nxt = a + i.size
            if mn in ('rts', 'rte', 'rtr'):
                term.add(a); break
            if mn.startswith('bra'):
                if tg: work.append(tg[-1])
                term.add(a); break
            if (mn.startswith('b') and not mn.startswith(('btst', 'bchg', 'bclr', 'bset', 'bf', 'bkpt'))) or mn.startswith('db'):
                if tg: work.append(tg[-1])
                a = nxt; continue
            if mn in ('jmp', 'jsr'):
                if tg and '(' not in s.replace('.l', '').replace('.w', ''):
                    work.append(tg[-1])
                elif '(pc)' in s and tg:
                    work.append(tg[-1])
                if mn == 'jmp':
                    term.add(a); break
                a = nxt; continue
            if mn in ('illegal', 'stop', 'reset'):
                break
            a = nxt
    before = [a for a in code if a + code[a] == slo]
    fence_before = before and before[0] in term
    after_live = (shi + 1) in code
    inside_live = [a for a in code if slo <= a <= shi]
    return A, C, T, before, fence_before, after_live, inside_live, len(code)


def main():
    ap = argparse.ArgumentParser(usage=__doc__)
    ap.add_argument('op'); ap.add_argument('data')
    ap.add_argument('--span', required=True)
    ap.add_argument('--code', default='0-100000')
    ap.add_argument('--allow-table', action='append', default=[])
    ap.add_argument('--plant', choices=('jsr', 'long', 'table'))
    ap.add_argument('--expect', choices=('dead', 'live'), default='dead')
    a = ap.parse_args()
    op = bytearray(open(a.op, 'rb').read()); da = bytearray(open(a.data, 'rb').read())
    print(f"# {a.op} sha1 {hashlib.sha1(op).hexdigest()}\n# {a.data} sha1 {hashlib.sha1(da).hexdigest()}")
    slo, shi = (int(x, 16) for x in a.span.split('-'))
    ranges = [tuple(int(x, 16) for x in r.split('-')) for r in a.code.split(',')]
    allow = set()
    for t in a.allow_table:
        b, r = t.split(':'); allow.add((int(b, 16), int(r, 16)))
    if a.plant:
        top = (ranges[-1][1] - 0x10) & ~1
        if a.plant == 'jsr':
            op[top:top + 2] = b'\x4e\xb9'; op[top + 2:top + 6] = slo.to_bytes(4, 'big')
        elif a.plant == 'long':
            da[len(da) - 0x10:len(da) - 0xC] = slo.to_bytes(4, 'big')
        else:   # move.w (d8,pc,d0.w),d1 base = at+2+d8 -> rows at at+6..: row 0 a span target. A 16-bit row
            # reaches only +-32K, so this plant goes 0x200 past the span (live code, overwritten in memory only)
            top = (shi + 0x200) & ~1
            B = top + 6
            op[top:top + 4] = b'\x32\x3b\x00\x04'          # move.w $(top+6)(pc,d0.w),d1  (d8 = 4: base = top+2+4)
            op[top + 4:top + 6] = b'\x4e\x75'              # rts
            op[B:B + 2] = ((slo - B) & 0xFFFF).to_bytes(2, 'big')
            op[B + 2:B + 4] = b'\x00\x04'
        print(f"# PLANT {a.plant} at PRG:0x{top:06X}{' (data view offset 0x%X)' % (len(da) - 0x10) if a.plant == 'long' else ''} (in memory only)")
    A, C, T, before, fence, after_live, inside, n = judge(op, da, slo, shi, ranges, allow)
    print(f"# span PRG:0x{slo:06X}-0x{shi:06X}; code ranges {', '.join(f'PRG:0x{lo:06X}-0x{hi:06X}' for lo, hi in ranges)}; "
          f"allowed table rows {sorted((hex(b), hex(r)) for b, r in allow)}; instructions reached {n}")
    for x in A: print(f"REF A  insn @PRG:0x{x[0]:06X} {x[1]}")
    for x in C: print(f"REF C  long in {x[0]} view @0x{x[1]:06X}")
    for x in T: print(f"REF T  table PRG:0x{x[0]:06X} ({x[4]} view; site PRG:0x{x[1]:06X}) row 0x{x[2]:X} -> PRG:0x{x[3]:06X}")
    for x in inside: print(f"LIVE   reached instruction inside the span @PRG:0x{x:06X}")
    b = f"@PRG:0x{before[0]:06X}" if before else "none"
    print(f"FENCE  before: instruction ending at the span start {b}, unconditional transfer: {'yes' if fence else 'no'}; "
          f"after: PRG:0x{shi + 1:06X} reached: {'yes' if after_live else 'no'}")
    dead = not A and not C and not T and not inside and fence and after_live
    print(f"VERDICT {'DEAD' if dead else 'NOT DEAD'}: refs A {len(A)} C {len(C)} T {len(T)}, live inside {len(inside)}, "
          f"fenced {'yes' if fence and after_live else 'no'}")
    ok = dead if a.expect == 'dead' else not dead
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
