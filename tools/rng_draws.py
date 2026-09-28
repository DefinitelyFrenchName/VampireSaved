#!/usr/bin/env python3
"""rng_draws.py — the reader of tests/audit_rng_draws.sh (GitHub #176, 14z-185): the engine RNG's DRAWS on each leg,
attributed to their callers, compared ours against native and legacy-ours against pristine vsavj.

  python3 tools/rng_draws.py <tap dir> <placements.json> <vs2 opcodes> <ours opcodes> <hui extract> <don extract> <pyr extract>
      [--plant relabel|drop|map|strip|block]

Reads rt_<leg>.txt (tests/lua/rng_draws.lua, RPCS = the routine's first instruction, RSTACKN = 48) for the legs
leilei_vsavj, leilei_ours and <tenant>_native / <tenant>_ours (huitzil, donovan, pyron). Prints the ROWS the gate
freezes, then one CHECK line per structural check, and exits 1 if any check fails:
  (a) legacy   leilei_ours equals leilei_vsavj draw for draw (frame label, caller, word)
  (b) keys     a draw whose stack holds a return address into the tenant's code (native: its vs2 extract regions;
               ours: its placement regions, mapped to native) is keyed by the innermost such address; a key seen on
               BOTH legs must count alike (one-leg keys are rows, frozen by the gate)
  (c) objloop  the object loop's draws (the draws whose caller is the loop: vsavj 0x0220A0, vs2 0x020A50) count alike
  (e) chain    on every leg, each draw's word is the generator's step of the previous draw's word, so no draw was missed
  (f) tenantless  legacy ours has no draw with a tenant frame on its stack
  (g) block    each tenant's tracker-call block (the return addresses of its per-tracker calls, declared below and
               VERIFIED against the vs2 image: a jsr abs.l into vs2's motion helpers 0x29104..0x291EC before each) is on
               the stack of NO native draw, raw presence at any depth, and of at least one ours draw
The plants (the gate's must-fire controls): relabel one legacy-ours caller; drop one huitzil_ours draw; shift the
ours->native map by 2; drop ours' first draw of a key native also has; put the huitzil block's first address on one
native stack.

The generator (vsavj PRG:0x014E8A, vs2 0x01357E, byte-identical): hi' = high byte of 3*W, lo' = lo + hi'.
"""
import collections, hashlib, json, sys

TENANTS = ("huitzil", "donovan", "pyron")
OBJLOOP = {"vsavj": 0x0220A0, "vs2": 0x020A50}
# the tenants' tracker-call blocks: the native (vs2) return address of each per-tracker jsr, read from the vs2 image
# at 14z-185 (build/agent185/t176); verified at run time by verify_blocks()
BLOCK = {"huitzil": [0x55238 + 14 * i for i in range(10)],
         "donovan": [0x59A2C + 14 * i for i in range(9)],
         "pyron": [0x579CC + 14 * i for i in range(10)]}
HELPERS = (0x29104, 0x291EC)


def step(w):
    h = ((3 * w) & 0xFFFF) >> 8
    return (h << 8) | (((w & 0xFF) + h) & 0xFF)


def w16(img, a):
    return (img[a] << 8) | img[a + 1] if 0 <= a < len(img) - 1 else -1


def is_call(img, r):
    if r < 6 or r >= len(img):
        return False
    if w16(img, r - 6) == 0x4EB9:
        return True
    x = w16(img, r - 4)
    if x in (0x4EB8, 0x6100, 0x4EBA, 0x4EBB) or 0x4EA8 <= x <= 0x4EB7:
        return True
    y = w16(img, r - 2)
    return 0x4E90 <= y <= 0x4E97 or ((y >> 8) == 0x61 and (y & 0xFF) not in (0, 0xFF))


def load(path):
    """-> list of (label, ret, word, [stack longs]); refuses a tap with no END line"""
    out, ended = [], False
    for line in open(path):
        t = line.split()
        if not t:
            continue
        if t[0] == "END":
            ended = True
        if t[0] != "R":
            continue
        stk = [int(x, 16) & 0xFFFFFF for x in t[t.index("stk") + 1].split(",")] if "stk" in t else []
        out.append((int(t[1]), int(t[t.index("ret") + 1], 16), int(t[t.index("data") + 1], 16) & 0xFFFF, stk))
    if not ended:
        sys.exit(f"VOID: {path} has no END line")
    return out


def main():
    a = [x for x in sys.argv[1:] if not x.startswith("--")]
    plant = sys.argv[sys.argv.index("--plant") + 1] if "--plant" in sys.argv else ""
    D, PL, V2, OURS, EXT = a[0], a[1], a[2], a[3], dict(zip(TENANTS, a[4:7]))
    img = {"native": open(V2, "rb").read(), "ours": open(OURS, "rb").read()}
    pl = json.load(open(PL))["regions"]
    shift = 2 if plant == "map" else 0

    OURS_REGS = {t: [(v["dst"], v["dst"] + v["len"], v["src"] - v["dst"] + shift) for k, v in pl.items()
                     if (("@" not in k) if t == "donovan" else k.endswith("@" + t))] for t in TENANTS}
    NAT_REGS = {}
    for t in TENANTS:
        NAT_REGS[t] = []
        for v in json.load(open(f"{EXT[t]}/regions.json"))["regions"].values():
            s = int(v["src"], 16) if isinstance(v["src"], str) else v["src"]
            n = v["len"] if isinstance(v["len"], int) else int(v["len"], 16)
            NAT_REGS[t].append((s, s + n, 0))
    ours_regs, nat_regs = OURS_REGS.get, NAT_REGS.get
    calls = {}

    def key_of(stk, regs, im):
        for v in stk:
            for s, e, off in regs:
                if s <= v < e:
                    c = calls.get((id(im), v))
                    if c is None:
                        c = calls[(id(im), v)] = is_call(im, v)
                    if c:
                        return v + off
        return None

    legs = {}
    for leg in ["leilei_vsavj", "leilei_ours"] + [f"{t}_{s}" for t in TENANTS for s in ("native", "ours")]:
        p = f"{D}/rt_{leg}.txt"
        legs[leg] = load(p)
        print(f"# {leg}: {len(legs[leg])} draws, trace sha1 {hashlib.sha1(open(p, 'rb').read()).hexdigest()[:12]}")
    print(f"# images: vs2 {hashlib.sha1(img['native']).hexdigest()[:12]}, ours {hashlib.sha1(img['ours']).hexdigest()[:12]}; "
          f"placements {hashlib.sha1(open(PL, 'rb').read()).hexdigest()[:12]}")
    if plant == "relabel":
        x = legs["leilei_ours"][500]; legs["leilei_ours"][500] = (x[0], x[1] + 2, x[2], x[3])
    if plant == "drop":
        del legs["huitzil_ours"][900]
    if plant == "block":
        x = legs["huitzil_native"][0]; legs["huitzil_native"][0] = (x[0], x[1], x[2], x[3] + [BLOCK["huitzil"][0]])

    fails = []
    # (a) legacy
    A, B = legs["leilei_vsavj"], legs["leilei_ours"]
    strip = lambda L: [(f, r, w) for f, r, w, _ in L]
    same = strip(A) == strip(B)
    first = next((i for i, (x, y) in enumerate(zip(strip(A), strip(B))) if x != y), None)
    print(f"legacy\tleilei\tdraws\t{len(A)}\t{len(B)}\t{'identical' if same else f'first-difference-at-{first}'}")
    if not same:
        fails.append("(a) legacy ours differs from pristine vsavj")
    # (e) chain
    for leg, L in legs.items():
        br = sum(1 for (_, _, w0, _), (_, _, w1, _) in zip(L, L[1:]) if step(w0) != w1)
        print(f"chain\t{leg}\tbreaks\t{br}")
        if br:
            fails.append(f"(e) {leg}: {br} break(s) in the draw chain")
    # (f) tenantless legacy ours
    allregs = [r for t in TENANTS for r in ours_regs(t)]
    n = sum(1 for _, _, _, stk in legs["leilei_ours"] if key_of(stk, allregs, img["ours"]) is not None)
    print(f"tenantless\tleilei_ours\t{n}")
    if n:
        fails.append(f"(f) legacy ours has {n} draw(s) with a tenant frame")
    # (g) the declared blocks, verified against the vs2 image
    for t, blk in BLOCK.items():
        bad = [hex(r) for r in blk if not (w16(img["native"], r - 6) == 0x4EB9 and HELPERS[0] <= (w16(img["native"], r - 4) << 16 | w16(img["native"], r - 2)) <= HELPERS[1])]
        print(f"blockdecl\t{t}\t{len(blk)}\t{'verified' if not bad else 'NOT ' + ','.join(bad)}")
        if bad:
            fails.append(f"(g) {t}: declared block entries not a jsr into the motion helpers: {bad}")
    for t in TENANTS:
        N, O = legs[f"{t}_native"], legs[f"{t}_ours"]
        # (c) object loop
        on, oo = sum(1 for _, r, _, _ in N if r == OBJLOOP["vs2"]), sum(1 for _, r, _, _ in O if r == OBJLOOP["vsavj"])
        print(f"objloop\t{t}\t{on}\t{oo}")
        if on != oo:
            fails.append(f"(c) {t}: object loop {on} native, {oo} ours")
        # (b) keys
        kn = collections.Counter(k for k in (key_of(s, nat_regs(t), img["native"]) for _, _, _, s in N) if k is not None)
        skip, skipped, ko = set(kn) if plant == "strip" else set(), False, collections.Counter()
        for _, _, _, s in O:
            k = key_of(s, ours_regs(t), img["ours"])
            if k is None:
                continue
            if k in skip and not skipped:
                skipped = True
                continue
            ko[k] += 1
        for k in sorted(set(kn) | set(ko)):
            side = "both" if k in kn and k in ko else ("native-only" if k in kn else "ours-only")
            print(f"key\t{t}\t{k:#08x}\t{side}\t{kn.get(k, 0)}\t{ko.get(k, 0)}")
            if side == "both" and kn[k] != ko[k]:
                fails.append(f"(b) {t}: key {k:#x} native {kn[k]}, ours {ko[k]}")
        # (g) the block, raw presence at any depth
        blk = set(BLOCK[t])
        blo = set()
        for s, e, off in ours_regs(t):
            blo |= {r - off for r in blk if s <= r - off < e}
        bn = sum(1 for _, _, _, s in N if set(s) & blk)
        bo = sum(1 for _, _, _, s in O if set(s) & blo)
        print(f"block\t{t}\t{bn}\t{bo}")
        if bn or not bo:
            fails.append(f"(g) {t}: the tracker block is on {bn} native and {bo} ours draw stack(s) (must be 0 and >0)")
    for f in fails:
        print(f"CHECK FAIL\t{f}")
    print("CHECK " + ("PASS" if not fails else f"FAIL ({len(fails)})"))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
