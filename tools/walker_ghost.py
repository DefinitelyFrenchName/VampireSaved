#!/usr/bin/env python3
"""walker_ghost.py — the reader of tests/audit_walker_ghost.sh (14z-91; re-stated 14z-185, GitHub #143): where each
object-pool walker's `jsr (A0)` pushes its return address, read from tests/lua/walker_sp.lua's runs.

  python3 tools/walker_ghost.py <run dir> <frozen toml> <opcode image> [--freeze] [--no-frozen]
                                [--frozen-shift N] [--extra-mask LO-HI] [--map RELOC=VANILLA ...]

The run dir holds one walker_sp.lua output per replay (<replay>.txt). Per site (the `jsr (A0)` address; the walker
entry is site - 0x1E) the checks are:
  (a) LIVE      the site fired (a site with no dispatch is a dead instrument, not a finding)
  (b) GROUND    every long on top of the stack the instrument read is a genuine return address: the end of a
                `jsr abs.l <walker entry>` in the vsavj opcode image. A read of the wrong stack (the supervisor stack,
                the pre-14z-185 read) finds work-RAM values there and FAILS (docs/platform/gotchas.md, the M68000 entry)
  (c) VISIBLE   the pushed long, [min-4, max-1], overlaps NO range of any legacy-oracle mask (the union of every
                tests/expected/**/mask): no mask hides a relocated walker's differing return address from the
                oracle's checksum. That the oracle's verdicts then catch a differing byte there is NOT this check:
                measured for one planted byte only (14z-185). (Until 14z-185 the gate asserted the
                opposite, that the push lay INSIDE the masked dead-stack window; that premise was measured false —
                the walkers run in user mode and the push lands in unmasked RAM. RETRACTED, #143.)
  (d) FROZEN    the live range (sp_min, sp_max) equals build/manifest/walker_ghost.toml's; a moved range is re-measured
                and re-frozen deliberately (--freeze), never absorbed. With --map RELOC=VANILLA (the RELOCATED leg:
                a relocated walker's `jsr (A0)` on a merged build, the opcode image the build's own), the relocated
                site is compared with the VANILLA site's frozen range — the relocation pushes at the same depth
Not covered (the maintainer's ruling, 14z-185, "Freeze the real ranges"): the legacy oracle's window, composite and
flicker verdicts TOLERATE divergences inside ratified ranges, so a push surviving to a checksum there would pass;
this gate does not measure whether one does.
The control flags: --frozen-shift N moves the frozen sp_min by N (check (d) must fail); --extra-mask adds a mask range
over the push (check (c) must fail); --no-frozen skips (d) (a one-replay control run).
"""
import glob, os, re, sys


def main():
    args = [a for a in sys.argv[1:]]
    def flag(name, has_value=False):
        if name not in args:
            return None
        i = args.index(name)
        v = args[i + 1] if has_value else True
        del args[i:i + (2 if has_value else 1)]
        return v
    freeze, nofrozen = flag("--freeze"), flag("--no-frozen")
    mapping = {}
    while "--map" in args:
        r, v = flag("--map", True).split("=")
        mapping[int(r, 16)] = int(v, 16)
    shift = int(flag("--frozen-shift", True) or 0)
    extra = flag("--extra-mask", True)
    W, FROZEN, IMG = args[0], args[1], args[2]
    img = open(IMG, "rb").read()
    w16 = lambda a: (img[a] << 8) | img[a + 1] if 0 <= a < len(img) - 1 else -1   # a RAM value is no code address

    masks = set()
    for p in glob.glob("tests/expected/**/mask", recursive=True):
        for r in open(p).read().strip().split(","):
            lo, hi = (int(x, 16) for x in r.split("-"))
            masks.add((0xFF0000 + lo, 0xFF0000 + hi))
    if extra:
        lo, hi = (int(x, 16) for x in extra.split("-"))
        masks.add((lo, hi))

    sites, incomplete = {}, []
    files = sorted(glob.glob(f"{W}/*.txt"))
    for f in files:
        txt = open(f).read()
        if "SPEND" not in txt:
            incomplete.append(os.path.basename(f)); continue
        for m in re.finditer(r"SP (\w+) hits (\d+) min (\S+) max (\S+)", txt):
            a, h = int(m.group(1), 16), int(m.group(2))
            s = sites.setdefault(a, {"hits": 0, "live": 0, "min": None, "max": None, "rets": {}, "super": 0, "user": 0})
            s["hits"] += h
            if h:
                s["live"] += 1
                lo, hi = int(m.group(3), 16), int(m.group(4), 16)
                s["min"] = lo if s["min"] is None else min(s["min"], lo)
                s["max"] = hi if s["max"] is None else max(s["max"], hi)
        for m in re.finditer(r"MODE (\w+) super (\d+) user (\d+)", txt):
            s = sites[int(m.group(1), 16)]; s["super"] += int(m.group(2)); s["user"] += int(m.group(3))
        for m in re.finditer(r"RET (\w+) : (.*)", txt):
            s = sites[int(m.group(1), 16)]
            for tok in m.group(2).split():
                k, c = tok.split("="); s["rets"][int(k, 16)] = s["rets"].get(int(k, 16), 0) + int(c)
    fail = []
    if incomplete:
        fail.append(f"incomplete runs: {', '.join(incomplete)}")
    frozen = {}
    if os.path.exists(FROZEN):
        cur = None
        for ln in open(FROZEN):
            m = re.match(r"site = 0x(\w+)", ln.strip())
            if m: cur = int(m.group(1), 16); frozen[cur] = {}
            m = re.match(r"(sp_min|sp_max) = 0x(\w+)", ln.strip())
            if m and cur is not None: frozen[cur][m.group(1)] = int(m.group(2), 16)
    out = ["# build/manifest/walker_ghost.toml — FROZEN live-stack range at each object-pool walker's `jsr (A0)`",
           "# (14z-91; re-measured on the LIVE stack 14z-185, GitHub #143 — until then this held the idle",
           "# supervisor stack, a constant 0xff7ff6). Regenerate with tests/audit_walker_ghost.sh --freeze.",
           "# The relocated walker pushes a different return address at [sp_min-4, sp_max-1]; the gate asserts",
           "# that range lies OUTSIDE every legacy-oracle mask (no mask hides it from the oracle's checksum).",
           "schema = 2"]
    print(f"# {len(files)} runs; masks (union of tests/expected/**/mask): "
          + ",".join(f"{lo:06x}-{hi:06x}" for lo, hi in sorted(masks)))
    for a in sorted(sites):
        s, entry = sites[a], a - 0x1E
        print(f"\n=== walker jsr (A0) at {a:#08x} (walker {entry:#08x}): {s['hits']:,} dispatches in {s['live']}/{len(files)} runs; "
              f"S bit set {s['super']:,}, clear {s['user']:,}")
        if not s["hits"]:
            fail.append(f"{a:#x}: zero dispatches — a dead instrument, not a finding"); continue
        push_lo, push_hi = s["min"] - 4, s["max"] - 1
        print(f"    live stack    {s['min']:#08x} .. {s['max']:#08x}; pushed long {push_lo:#08x} .. {push_hi:#08x}")
        bad = {r: c for r, c in s["rets"].items()
               if not (r >= 6 and w16(r - 6) == 0x4EB9 and ((w16(r - 4) << 16) | w16(r - 2)) == entry)}
        good = sum(s["rets"].values()) - sum(bad.values())
        print(f"    ground truth  {good:,} of {sum(s['rets'].values()):,} longs on top of the stack end a `jsr abs.l {entry:#08x}`"
              + ("" if not bad else f"; NOT: {', '.join(f'{r:#08x}x{c}' for r, c in sorted(bad.items())[:4])}"))
        if bad or not s["rets"]:
            fail.append(f"{a:#x}: GROUND — the instrument read a stack the walker's caller did not push onto")
        hit = [(lo, hi) for lo, hi in masks if lo <= push_hi and push_lo < hi]
        if hit:
            fail.append(f"{a:#x}: VISIBLE — the push {push_lo:#08x}..{push_hi:#08x} overlaps mask "
                        + ",".join(f"{lo:06x}-{hi:06x}" for lo, hi in hit) + ": the oracle would not see a relocated walker's return address")
        else:
            print(f"    visible       the push overlaps no range of any legacy-oracle mask")
        if not freeze and not nofrozen:
            fz = frozen.get(mapping.get(a, a), {})
            want = (fz.get("sp_min", -1) + shift, fz.get("sp_max", -1))
            if (s["min"], s["max"]) == want:
                print(f"    frozen        {want[0]:#08x} .. {want[1]:#08x} — as measured"
                      + (f" (the vanilla site {mapping[a]:#08x}'s frozen range)" if a in mapping else ""))
            else:
                fail.append(f"{a:#x}: FROZEN — the live range {s['min']:#08x}..{s['max']:#08x} differs from the frozen "
                            f"{want[0]:#08x}..{want[1]:#08x}: re-measure and re-freeze deliberately")
        out += ["", "[[site]]", f"site = 0x{a:05x}", f"sp_min = 0x{s['min']:06x}", f"sp_max = 0x{s['max']:06x}",
                f"hits = {s['hits']}", f"replays = {s['live']}"]
    for f in fail:
        print(f"CHECK FAIL\t{f}")
    if freeze and not fail:
        open(FROZEN, "w").write("\n".join(out) + "\n")
        print(f"\nFROZE {FROZEN}")
        return 0
    print("\n" + ("WALKER GHOST: PASS" if not fail else "WALKER GHOST: FAIL"))
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
