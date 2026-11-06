#!/usr/bin/env python3
"""audit_dead_span.py — is a byte span of a 68000 opcode view PROVEN DEAD: nothing can execute it and nothing can
read it? (14z-216, GitHub #294: the per-frame palette table's 16-bit word must reach a jump to the ported routine, so
it needs six dead bytes within PRG:0x022DEC-0x032DEB; promoted from build/agent216/rc294/dead/.)

  python3 tools/audit_dead_span.py <opcodes.bin> <data.bin> --span 024024-024029
        [--code 0-100000[,lo-hi...]] [--spaces MANIFEST.toml ...] [--allow-table BASE:ROW] [--allow-pcidx BASE]
        [--plant jsr|long|table|unallow|fallthrough] [--expect live|only]

A span is judged DEAD only when all six hold, each computed over-approximately (a false reference can only HIDE a
dead byte, never invent one):
  A  no instruction decoded at EVERY even address of the code ranges (not one linear path) names any span address
     in its operand text (branch targets, abs.w/abs.l, capstone-resolved PC-relative EAs, #immediates);
  C  no 32-bit big-endian value at ANY 2-aligned offset of EITHER full view equals a span address;
  T  no table gives a span address: every `(d8,PC,Xn)` EA and every lea/pea/movea.l/move.l #imm operand inside the
     code ranges is a table base B; its words B+0.. (the opcode view for a PC-indexed base, BOTH views for a base
     loaded into a register, which CPS-2 reads through the data view) are read as offsets while B+o stays below the
     lowest forward target seen (the jump-table extent rule, at most 0x400 bytes), and its longs likewise; a row
     that gives a span address is a reference unless named by --allow-table (the port's own row);
  D  no PC-indexed DATA read can land in it: every `(d8,PC,Xn)` base B inside the code ranges makes B-0x100..B+0xFF
     referenced bytes (an index register can hold anything, a negative value too (14z-221c, run -1664), so the extent is a cap, not a measurement — a byte
     table read `move.b $B(pc,d0.w),d0` after `andi.w #$f,d0` reads 16 bytes; 14z-221c, #363: PRG:0x0236CE-0x0236D3
     passed A, C, T and L and is entries 10-15 of such a table at PRG:0x0236C4, read at PRG:0x023694 — rule T reads a
     base's rows as OFFSETS only, and its data decoded as a reached `bra.w`, which satisfied L);
  R  the same for a REGISTER-loaded base (14z-221c, rule-checker run 2026-11-06-1655): every lea/pea/movea.l/move.l #imm
     operand B in the code ranges, odd or even, and every adda.l/addi.l #imm (a constant added to a register), makes
     B-0x100..B+0xFF referenced bytes, as a table read through (An,Xn) or (d16,An) can
     land there, a negative index or displacement too; rule T reads such a base's rows only as offsets. A move.l #imm is counted though it may be a plain value (a
     16.16 speed) — over-approximate, so the caller names it with --allow-pcidx and its sites, as for rule D;
  L  the span is FENCED by live code: EVERY reached instruction ending exactly where the span starts is an
     unconditional transfer, none straddles the span's first byte (14z-221c, runs -1663 and -1664) (bra/jmp/rts/rte/rtr — no fall-through), and the byte after the span is reached. Reached
     = recursive descent from the 256 vectors, every in-range long of both views, and every table row (rule T),
     following Bcc/DBcc both ways, BSR/JSR target + fall-through, BRA/JMP target. A fenced span cannot be the tail
     of a data table without that table overlapping live code.
--allow-pcidx BASE accepts rule D's reference from one PC-indexed base: the caller names it and must carry a runtime
bound for it (that the read never runs, or never lands in the span) — rule D's 0x100 (on either side of the base: an index or displacement may be negative) is a cap, not an extent.
What it cannot see, stated: an address computed arithmetically at run time from no constant (base + a computed
offset with neither the base nor the result appearing anywhere), and a reader that reaches the span through a
table whose base is formed that way. The runtime bound (execution counts over the legacy corpus) is a separate
instrument (build/agent216/rc294/dead/exec_bound.sh); MAME read taps are blind to ROM fetches (RH-15).

--plant (controls; the image is changed IN MEMORY only, then every check re-runs over it):
  jsr    a `jsr <span start>.l` written at the first even address of the LAST code range's top 0x10 bytes -> A fires
  long   the span start as a long written at data-view offset len-0x10 -> C fires
  lea    a `lea <span start - 0x10>.l,a0` written where the jsr plant goes -> R fires
  pcidx  a `move.b $<span start - 0x10>(pc,d0.w),d0` written 0x40 below the span (in memory only) -> D fires
  lea-odd  a `lea <span start - 0x0F>.l,a0` (an ODD base) where the jsr plant goes -> R fires
  adda   an `adda.l #<span start - 0x10>,a0` where the jsr plant goes -> R fires
  table-data  a `lea B.l,a0` (B 0x300 past the span) and, in the DATA view at B, a row 0 giving the span start -> T
         fires through the data view (a register-loaded table's rows are read in both views)
  second-entry-alias  second-entry with the long 0xFF<span start - 2> -> the fence fails (the descent's 24-bit entries)
  jsr-alias / long-alias / lea-alias  the jsr, long and lea plants with a nonzero top byte (0x01, 0xFF, 0xFF): the
         68000 ignores the top byte of an address, so each must still fire A, C or R
  pea / movea / addi  `pea <span start - 0x10>.l`, `movea.l #<it>,a0`, `addi.l #<it>,d0` there -> R fires (each listed form)
  pcidx-above  the same read through a base 0x10 ABOVE the span's end (a negative index reaches it) -> D fires
  straddle  a 4-byte `move.w #imm,d0` written at the span start - 2 and a long naming it: a reached instruction straddles
         the span's first byte -> the fence fails
  second-entry  the long (span start - 2) in the data view: a second path enters just before the span -> the fence fails
  reread a second `move.b <--reload-base>(pc,d0.w),d0` 0x40 below that base (in memory only): rule D's site binding
  reload a second `lea <--reload-base>.l,a0` near the top of the code window: an accepted base gains a site, so a row or
         base accepted for named sites is a reference again (T, D or R fires)
--allow-table BASE:ROW@SITE/SITE accepts the row only while its base is named at exactly those sites
--allow-pcidx BASE@SITE/SITE accepts the base only while its readers/loaders are exactly those sites
  table  a `move.w (d8,PC,D0.w),D1` and a two-row word table whose row 0 gives the span start, planted 0x200 bytes
         past the span (a 16-bit row reaches only +-32K) -> T fires
  unallow      each --allow-table row overwritten with the word of the row before it (opcode view) -> the allowed
               row no longer reaches the span (#354: "exactly one" must also fail on NONE)
  fallthrough  two `nop`s written over the 4 bytes ending at the span start (the fence's bra.w) -> L fires
--expect live: exit 0 only when the verdict is NOT DEAD (the known-live control span).
--expect only (14z-221c, GitHub #354 — a span a BUILT image reaches on purpose): exit 0 only when A and C are empty,
  every T row is an --allow-table row, EVERY --allow-table row is seen giving a span address, and the span is fenced
  (L's fence: no fall-through into it, the byte after it reached). Reached instructions inside the span are printed
  but not judged: the allowed row reaches them by construction, and every other way in is A, C, T or the fence.
--spaces: add each [[space]] (start-end) of a build manifest to the code ranges, clipped to the image's length — the
  places ported code may live on a built image (hole_a, hole_b, wide_ext), beside the --code ranges.
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


def judge(op, da, slo, shi, ranges, allow, allow_pcidx=(), allow_sites=None):
    m = md()
    incode = lambda a: any(lo <= a < hi for lo, hi in ranges) and not a & 1
    inrange = lambda a: any(lo <= a < hi for lo, hi in ranges)
    # The 68000's address bus has 24 bits (14z-221c, rule-checker run 2026-11-06-1676): an instruction operand is read
    # with its top byte ignored (rules A and R); a 32-bit long in data (rules C and T) counts when its top byte is 0x00 or
    # 0xFF, the forms a 68000 address constant takes (a long with another top byte aliasing the span is not seen: across
    # both full views about one such long per 6-byte span turns up by chance, measured 2026-11-06 on pristine vsavj).
    a24 = lambda x: x & 0xFFFFFF
    l24 = lambda x: x & 0xFFFFFF if (x >> 24) in (0x00, 0xFF) else -1
    span = set(range(slo, shi + 1))
    A, C, T, TA, D = [], [], [], set(), []
    bases = {}
    pcidx = {}
    regb = {}   # rule R: register-loaded base -> every site loading it
    bsites = {}   # every base (PC-indexed or register-loaded) -> every site naming it (an allowed row's site binding)
    for lo, hi in ranges:
        for a in range(lo & ~1, hi, 2):
            i = dec(m, op, a)
            if not i:
                continue
            for neg, h in HEXRE.findall(i.op_str):
                if not neg and a24(int(h, 16)) in span:
                    A.append((a, f"{i.mnemonic} {i.op_str}"))
            p = PCIDX.search(i.op_str)
            if p:
                bases.setdefault(int(p.group(1), 16), [a, set()])[1].add('op')
                pcidx.setdefault(int(p.group(1), 16), []).append(a)   # EVERY site, not the first (14z-221c, run -1653)
                bsites.setdefault(int(p.group(1), 16), []).append(a)
            # capstone names them `lea.l` / `pea.l` (14z-221c: the exact-name test `in ('lea', 'pea', ...)` never matched,
            # so no lea/pea base was ever collected, for rule T either)
            elif (i.mnemonic.split('.')[0] in ('lea', 'pea') or i.mnemonic == 'movea.l'
                  or (i.mnemonic in ('move.l', 'adda.l', 'addi.l') and i.op_str.startswith('#'))):
                # adda.l/addi.l #imm too: a constant added to a register can form the base (14z-221c, run -1669)
                h = re.match(r'#?\$([0-9a-f]+)', i.op_str)
                B = a24(int(h.group(1), 16)) if h else -1
                if h and inrange(B):
                    # rule R: a base of EITHER parity (a byte table may start odd; 14z-221c, rule-checker run 2026-11-06-1669)
                    regb.setdefault(B, []).append(a)
                    bsites.setdefault(B, []).append(a)
                if h and incode(B):
                    # rule T reads an even base's rows as word offsets: a DATA-view read on CPS-2; the opcode view
                    # too, in case the same base is also read PC-relatively
                    bases.setdefault(B, [a, set()])[1].update(('op', 'data'))
    for name, v in (('op', op), ('data', da)):
        for a in range(0, len(v) - 3, 2):
            if l24(int.from_bytes(v[a:a + 4], 'big')) in span:
                C.append((name, a))
    DA = []   # rule D references ACCEPTED by --allow-pcidx: (base, every site reading through it, first span byte)
    for B, sites in pcidx.items():   # rule D
        hit = sorted(span & set(range(B - 0x100, B + 0x100)))   # both sides: an index or displacement may be negative (14z-221c, run -1664)
        if not hit or any(b == B for b, _ in allow):
            continue
        if B in allow_pcidx and allow_pcidx[B] in (None, set(sites)):
            DA.append((B, sites, hit[0]))
        else:   # not accepted, or accepted only for named sites and the readers differ (14z-221c, run -1660)
            D.append((B, sites[0], hit[0]))
    RR, RA = [], []   # rule R references, and those accepted by --allow-pcidx
    for B, sites in regb.items():
        hit = sorted(span & set(range(B - 0x100, B + 0x100)))   # both sides: an index or displacement may be negative (14z-221c, run -1664)
        if not hit or any(b == B for b, _ in allow):
            continue
        (RA if B in allow_pcidx and allow_pcidx[B] in (None, set(sites)) else RR).append((B, sites, hit[0]))
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
                x = l24(int.from_bytes(v[B + o:B + o + 4], 'big'))
                # an allowed row named with sites (BASE:ROW@SITE/SITE) is accepted only while its base is named at exactly
                # those sites: a new loader or reader of the base reopens it (14z-221c, rule-checker run 2026-11-06-1661)
                ok_row = (B, o // 2) in allow and (allow_sites or {}).get((B, o // 2)) in (None, set(bsites.get(B, [])))
                for cand in (t, x):
                    if cand in span and not ok_row:
                        T.append((B, site, o // 2, cand, vn))
                    elif cand in span:
                        TA.add((B, o // 2, cand, vn, site))
                    if incode(cand):
                        tg.append(cand)
                if t > B and incode(t):
                    lim = min(lim, t)
        rows[B] = tg
    # L: recursive descent
    entries = set()
    # the vectors and every long of both views enter the descent read as the 24-bit bus does (top byte 0x00 or 0xFF,
    # as rules C and T read a long; 14z-221c, rule-checker run 2026-11-06-1677)
    for a in range(0, 0x400, 4):
        x = l24(int.from_bytes(da[a:a + 4], 'big'))
        if incode(x):
            entries.add(x)
    for v in (op, da):
        for a in range(0, len(v) - 3, 2):
            x = l24(int.from_bytes(v[a:a + 4], 'big'))
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
            tg = [a24(int(h, 16)) for neg, h in HEXRE.findall(s) if not neg]   # 24-bit bus
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
    before = sorted(a for a in code if a + code[a] == slo)
    # EVERY reached instruction ending at the span start must be an unconditional transfer, and none may straddle the
    # span's first byte (14z-221c, rule-checker run 2026-11-06-1663: only the first was judged, a straddler never)
    straddle = sorted(a for a in code if a < slo < a + code[a])
    fence_before = bool(before) and all(x in term for x in before) and not straddle
    before = (before, straddle)
    after_live = (shi + 1) in code
    inside_live = [a for a in code if slo <= a <= shi]
    return A, C, T, TA, D, DA, RR, RA, before, fence_before, after_live, inside_live, len(code)


def main():
    ap = argparse.ArgumentParser(usage=__doc__)
    ap.add_argument('op'); ap.add_argument('data')
    ap.add_argument('--span', required=True)
    ap.add_argument('--code', default='0-100000')
    ap.add_argument('--allow-table', action='append', default=[])
    ap.add_argument('--allow-pcidx', action='append', default=[])
    ap.add_argument('--spaces', action='append', default=[])
    ap.add_argument('--plant', choices=('jsr', 'long', 'table', 'lea', 'pcidx', 'reload', 'reread', 'second-entry', 'straddle', 'pcidx-above', 'lea-odd', 'adda', 'pea', 'movea', 'addi', 'jsr-alias', 'long-alias', 'lea-alias', 'second-entry-alias', 'table-data', 'unallow', 'fallthrough'))
    ap.add_argument('--reload-base', default='')
    ap.add_argument('--expect', choices=('dead', 'live', 'only'), default='dead')
    a = ap.parse_args()
    op = bytearray(open(a.op, 'rb').read()); da = bytearray(open(a.data, 'rb').read())
    print(f"# {a.op} sha1 {hashlib.sha1(op).hexdigest()}\n# {a.data} sha1 {hashlib.sha1(da).hexdigest()}")
    slo, shi = (int(x, 16) for x in a.span.split('-'))
    ranges = [tuple(int(x, 16) for x in r.split('-')) for r in a.code.split(',')]
    if a.spaces:
        sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
        from _minitoml import loads
        for f in a.spaces:
            for sp in loads(open(f).read()).get('space', []):
                lo, hi = sp['start'], min(sp['end'], len(op))
                if lo < hi and not any(l <= lo and hi <= h for l, h in ranges):
                    ranges.append((lo, hi))
        ranges.sort()
    allow, allow_sites = set(), {}
    for t in a.allow_table:
        br, _, st = t.partition('@')
        b, r = br.split(':'); allow.add((int(b, 16), int(r, 16)))
        allow_sites[(int(b, 16), int(r, 16))] = {int(x, 16) for x in st.split('/')} if st else None
    if a.plant in ('unallow', 'fallthrough'):
        if a.plant == 'unallow':
            if not allow:
                sys.exit("audit_dead_span: --plant unallow needs an --allow-table row")
            for b, r in sorted(allow):
                if r < 1:
                    sys.exit("audit_dead_span: --plant unallow needs an allowed row above row 0")
                op[b + 2 * r:b + 2 * r + 2] = op[b + 2 * r - 2:b + 2 * r]
                print(f"# PLANT unallow: table PRG:0x{b:06X} row 0x{r:X} given row 0x{r - 1:X}'s word (in memory only)")
        else:
            op[slo - 4:slo] = b'\x4e\x71\x4e\x71'
            print(f"# PLANT fallthrough: two nops at PRG:0x{slo - 4:06X}-0x{slo - 1:06X} (in memory only)")
    elif a.plant:
        top = (ranges[-1][1] - 0x10) & ~1
        if a.plant == 'jsr':
            op[top:top + 2] = b'\x4e\xb9'; op[top + 2:top + 6] = slo.to_bytes(4, 'big')
        elif a.plant == 'long':
            da[len(da) - 0x10:len(da) - 0xC] = slo.to_bytes(4, 'big')
        elif a.plant == 'reload':   # a second `lea <base>.l,a0` of an accepted base, 0x20 below the top (its site binding)
            if not a.reload_base:
                sys.exit("audit_dead_span: --plant reload needs --reload-base")
            top = (ranges[-1][1] - 0x20) & ~1
            op[top:top + 2] = b'\x41\xf9'; op[top + 2:top + 6] = int(a.reload_base, 16).to_bytes(4, 'big')
        elif a.plant == 'second-entry':   # the long (span start - 2) at data offset len-0x20: the descent enters 2 bytes
            # before the span, so a second reached instruction ends at, or straddles, its start (the fence's every-predecessor
            # rule; 14z-221c, rule-checker run 2026-11-06-1663)
            da[len(da) - 0x20:len(da) - 0x1C] = (slo - 2).to_bytes(4, 'big')
        elif a.plant == 'table-data':   # lea B.l,a0 with B = span end + 0x300 (beyond rule R's 0x100), and in the DATA view at
            # B a word row 0 giving the span start: a register-loaded table read through the data view (rule T's data-view
            # half; 14z-221c, rule-checker run 2026-11-06-1678)
            B = (shi + 0x300) & ~1
            op[top:top + 2] = b'\x41\xf9'; op[top + 2:top + 6] = B.to_bytes(4, 'big')
            da[B:B + 2] = ((slo - B) & 0xFFFF).to_bytes(2, 'big')
        elif a.plant == 'second-entry-alias':   # second-entry with the long 0xFF<span start - 2>: the descent enters there as the
            # 24-bit bus does (14z-221c, rule-checker run 2026-11-06-1677)
            da[len(da) - 0x20:len(da) - 0x1C] = (0xFF000000 | (slo - 2)).to_bytes(4, 'big')
        elif a.plant == 'straddle':   # move.w #imm,d0 (4 bytes) at span start - 2, reached through the long (span start - 2)
            # at data offset len-0x20: a reached instruction straddles the span's first byte (14z-221c, run -1664)
            op[slo - 2:slo + 2] = b'\x30\x3c\x4e\x71'
            da[len(da) - 0x20:len(da) - 0x1C] = (slo - 2).to_bytes(4, 'big')
        elif a.plant == 'pcidx-above':   # move.b $<span end + 0x10>(pc,d0.w),d0 planted 0x40 below the span: a base ABOVE
            # the span, which a negative index reaches (rule D's two-sided window; 14z-221c, run -1664)
            top = (slo - 0x40) & ~1
            op[top:top + 4] = bytes([0x10, 0x3b, 0x00, (shi + 0x10) - (top + 2)])
        elif a.plant == 'reread':   # a second PC-indexed reader of an accepted base: move.b BASE(pc,d0.w),d0 at BASE-0x40
            if not a.reload_base:
                sys.exit("audit_dead_span: --plant reread needs --reload-base")
            b = int(a.reload_base, 16); top = (b - 0x40) & ~1
            op[top:top + 4] = bytes([0x10, 0x3b, 0x00, b - (top + 2)])
        elif a.plant == 'pcidx':   # move.b $<span start - 0x10>(pc,d0.w),d0 planted 0x40 below the span (rule D)
            top = (slo - 0x40) & ~1
            op[top:top + 4] = bytes([0x10, 0x3b, 0x00, (slo - 0x10) - (top + 2)])
        elif a.plant == 'lea-odd':   # lea <span start - 0x0F>.l,a0: an ODD register-loaded base (rule R takes either parity;
            # 14z-221c, rule-checker run 2026-11-06-1669)
            op[top:top + 2] = b'\x41\xf9'; op[top + 2:top + 6] = (slo - 0x0F).to_bytes(4, 'big')
        elif a.plant == 'adda':   # adda.l #<span start - 0x10>,a0: a constant added to a register forms the base (rule R)
            op[top:top + 2] = b'\xd1\xfc'; op[top + 2:top + 6] = (slo - 0x10).to_bytes(4, 'big')
        elif a.plant == 'jsr-alias':   # jsr $01<span start>.l: the 24-bit bus ignores the top byte (rule A; run -1676)
            op[top:top + 2] = b'\x4e\xb9'; op[top + 2:top + 6] = (0x01000000 | slo).to_bytes(4, 'big')
        elif a.plant == 'long-alias':   # the long 0xFF<span start> in the data view (rule C's 0xFF top byte)
            da[len(da) - 0x10:len(da) - 0xC] = (0xFF000000 | slo).to_bytes(4, 'big')
        elif a.plant == 'lea-alias':   # lea $FF<span start - 0x10>.l,a0 (rule R, top byte ignored)
            op[top:top + 2] = b'\x41\xf9'; op[top + 2:top + 6] = (0xFF000000 | (slo - 0x10)).to_bytes(4, 'big')
        elif a.plant in ('pea', 'movea', 'addi'):   # pea <b>.l / movea.l #<b>,a0 / addi.l #<b>,d0, b = span start - 0x10: each
            # form rule R lists, so a capstone name that stopped matching (the lea.l trap) fails its control (14z-221c, run -1674)
            op[top:top + 2] = {'pea': b'\x48\x79', 'movea': b'\x20\x7c', 'addi': b'\x06\x80'}[a.plant]
            op[top + 2:top + 6] = (slo - 0x10).to_bytes(4, 'big')
        elif a.plant == 'lea':   # lea <span start - 0x10>.l,a0: a register-loaded base whose 0x100 extent covers the span (rule R)
            op[top:top + 2] = b'\x41\xf9'; op[top + 2:top + 6] = (slo - 0x10).to_bytes(4, 'big')
        else:   # move.w (d8,pc,d0.w),d1 base = at+2+d8 -> rows at at+6..: row 0 a span target. A 16-bit row
            # reaches only +-32K, so this plant goes 0x200 past the span (live code, overwritten in memory only)
            top = (shi + 0x200) & ~1
            B = top + 6
            op[top:top + 4] = b'\x32\x3b\x00\x04'          # move.w $(top+6)(pc,d0.w),d1  (d8 = 4: base = top+2+4)
            op[top + 4:top + 6] = b'\x4e\x75'              # rts
            op[B:B + 2] = ((slo - B) & 0xFFFF).to_bytes(2, 'big')
            op[B + 2:B + 4] = b'\x00\x04'
        print(f"# PLANT {a.plant} at PRG:0x{top:06X}{' (data view offset 0x%X)' % (len(da) - 0x10) if a.plant == 'long' else ''} (in memory only)")
    # BASE, or BASE@SITE/SITE: accepted only while the base's readers (D) or loaders (R) are exactly the named sites
    apx = {}
    for x in a.allow_pcidx:
        b, _, st = x.partition('@')
        apx[int(b, 16)] = {int(t, 16) for t in st.split('/')} if st else None
    A, C, T, TA, D, DA, RR, RA, before, fence, after_live, inside, n = judge(op, da, slo, shi, ranges, allow, apx, allow_sites)
    print(f"# span PRG:0x{slo:06X}-0x{shi:06X}; code ranges {', '.join(f'PRG:0x{lo:06X}-0x{hi:06X}' for lo, hi in ranges)}; "
          f"allowed table rows {sorted((hex(b), hex(r)) for b, r in allow)}; allowed PC-indexed bases "
          f"{sorted(hex(b) + ('@' + '/'.join(hex(t) for t in sorted(v)) if v else '') for b, v in apx.items())}; instructions reached {n}")
    for x in A: print(f"REF A  insn @PRG:0x{x[0]:06X} {x[1]}")
    for x in C: print(f"REF C  long in {x[0]} view @0x{x[1]:06X}")
    for x in T: print(f"REF T  table PRG:0x{x[0]:06X} ({x[4]} view; site PRG:0x{x[1]:06X}) row 0x{x[2]:X} -> PRG:0x{x[3]:06X}")
    for x in D: print(f"REF D  PC-indexed base PRG:0x{x[0]:06X} (site PRG:0x{x[1]:06X}) reaches PRG:0x{x[2]:06X} within 0x100")
    for x in RR: print(f"REF R  register-loaded base PRG:0x{x[0]:06X} (site PRG:0x{x[1][0]:06X}) reaches PRG:0x{x[2]:06X} within 0x100")
    for x in RA: print(f"ALLOW R base PRG:0x{x[0]:06X} reaches PRG:0x{x[2]:06X} within 0x100; every site loading it: "
                       + ", ".join(f"PRG:0x{a:06X}" for a in sorted(x[1])))
    for x in DA: print(f"ALLOW D base PRG:0x{x[0]:06X} reaches PRG:0x{x[2]:06X} within 0x100; every site reading through it: "
                       + ", ".join(f"PRG:0x{a:06X}" for a in sorted(x[1])))
    for x in sorted(TA): print(f"ALLOW T table PRG:0x{x[0]:06X} ({x[3]} view; site PRG:0x{x[4]:06X}) row 0x{x[1]:X} -> PRG:0x{x[2]:06X}")
    seen = {(x[0], x[1]) for x in TA}
    for b, r in sorted(allow - seen): print(f"MISSING allowed row: table PRG:0x{b:06X} row 0x{r:X} gives no span address")
    for x in inside: print(f"LIVE   reached instruction inside the span @PRG:0x{x:06X}")
    bl, sl = before
    b = ", ".join(f"@PRG:0x{x:06X}" for x in bl) if bl else "none"
    if sl:
        b += "; STRADDLING the span start: " + ", ".join(f"@PRG:0x{x:06X}" for x in sl)
    print(f"FENCE  before: instruction ending at the span start {b}, unconditional transfer: {'yes' if fence else 'no'}; "
          f"after: PRG:0x{shi + 1:06X} reached: {'yes' if after_live else 'no'}")
    dead = not A and not C and not T and not D and not RR and not inside and fence and after_live
    if a.expect != 'only': print(f"VERDICT {'DEAD' if dead else 'NOT DEAD'}: refs A {len(A)} C {len(C)} T {len(T)} D {len(D)} R {len(RR)}, live inside {len(inside)}, "
          f"fenced {'yes' if fence and after_live else 'no'}")
    if a.expect == 'only':
        only = not A and not C and not T and not D and not RR and fence and after_live and seen == allow and bool(allow)
        rows = ', '.join(f'PRG:0x{b:06X} row 0x{r:X}' for b, r in sorted(allow)) or 'none'
        print(f"VERDICT {'REACHED ONLY' if only else 'REACHED OTHERWISE'}: allowed {rows} seen {len(seen)} of {len(allow)}; "
              f"other refs A {len(A)} C {len(C)} T {len(T)} D {len(D)} R {len(RR)}; fenced {'yes' if fence and after_live else 'no'}")
        sys.exit(0 if only else 1)
    ok = dead if a.expect == 'dead' else not dead
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
