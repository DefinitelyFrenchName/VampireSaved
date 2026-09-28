#!/usr/bin/env python3
"""facing_sweep.py — the reader of tests/audit_facing_sweep.sh (GitHub #159, 14z-185): Killshread Summon (ES)'s
facing writes at 32 P1-P2 geometries, native vs2 against the build under test, and which of vsavj's facing rules
could reproduce native's value per anim node.

  python3 tools/facing_sweep.py <tap dir> [--plant flip|perturb]

Reads w_native_<leg>.txt and w_ours_<leg>.txt (tests/lua/facing_tap.lua, RTAP=ff885c,2, writes from frame 3850) for
the legs L_<d> and R_<d>, d = 60..150 hex step 10. Prints the ROWS the gate freezes, then CHECK lines, and exits 1
if a check fails:
  leg    <leg> native <writes> <sha> ours <writes> <sha> SAME|DIFF
         every write to Demitri's +0x5C/+0x5D word, as (frame, mask, value) — writer PCs differ between the games
         and are not compared; sha = the first 12 hex of the sequence's sha1
  rule5  <leg> <values>   native's rule-5 stores (PC 0x0171E0, vs2's `move.b d0,$5d(a1)` in its rule-5 branch), in order
  build5 <leg> <values>   on each of those frames, the build's LAST write covering +0x5D (a byte store, mask 00ff, or
                          a word store, mask ffff; hex, comma-separated; - when it wrote none) — the value the build's
                          resolver left where native's rule 5 wrote
  masks  <leg> native <byte-lo> <byte-hi> <word> ours <byte-lo> <byte-hi> <word>   the writes by mask (00ff, ff00, ffff)
  geom   <leg> <first write's frame> native <P1 x> <P2 x> ours <P1 x> <P2 x>
         where the players stood at each leg's first facing write (the first contact's caller write, before any
         leg can differ): the pokes' LANDING, measured, not assumed
  geometries-distinct <n> <of>   distinct (P1 x, P2 x) pairs over the native legs
  node   <native node> <contacts> <rules that fit | NONE>
         at each native rule-5 contact, what each vsavj rule gives from that contact's state, as vsavj's resolver
         (PRG:0x18854) computes it: r0 = the value the resolver's caller wrote first (vs2 PC 0x017178), r1 = r0^1,
         r2 = victim +0x0B ^ 1, r3 = attacker +0x0A, r4 = 1 if P1 x < victim x (vsavj's rule-4 object is P1 on our
         build), neg = 1 if attacker x < victim x; a rule FITS a node if it equals native on every contact of it
  nodes-nofit <n> <of>
The checks: (a) every native leg has at least one rule-5 store (the Summon connected); (b) every rule-5 store
followed a caller write on the same frame and node (the r0 input is present); (c) on every leg the build's first
write is on native's frame with the players where native's stood (both legs ran the same geometry).
The plants (the gate's must-fire controls): flip — every native rule-5 value inverted before the node table (a
node that fits only the position rule then fits none, so nodes-nofit moves); perturb — the last write of ours'
L_60 leg XORed with 1 (its sha and verdict move).
"""
import collections, hashlib, sys

LEGS = [f"{s}_{d:x}" for s in ("L", "R") for d in range(0x60, 0x151, 0x10)]
NATIVE_STORE, NATIVE_FIRST = "0171e0", "017178"


def load(path):
    """-> (writes [(frame, mask, value)], rows [(frame, pc, fields)]); refuses a tap with no END line"""
    writes, rows, ended = [], [], False
    for line in open(path):
        t = line.split()
        if not t:
            continue
        if t[0] == "END":
            ended = True
        if t[0] != "W" or int(t[1]) < 3850:
            continue
        mask = t[9]
        writes.append((int(t[1]), mask, int(t[7], 16) & int(mask, 16)))   # every byte the write's mask covers
        rows.append((int(t[1]), t[3], mask, int(t[7], 16) & 0xFF, dict(zip(t[10::2], t[11::2]))))
    if not ended:
        sys.exit(f"VOID: {path} has no END line")
    return writes, rows


def sha(seq):
    return hashlib.sha1(repr(seq).encode()).hexdigest()[:12]


def main():
    a = [x for x in sys.argv[1:] if not x.startswith("--")]
    plant = sys.argv[sys.argv.index("--plant") + 1] if "--plant" in sys.argv else ""
    D = a[0]
    fails, per_node, out, geoms = [], collections.defaultdict(list), [], []
    for leg in LEGS:
        nw, nr = load(f"{D}/w_native_{leg}.txt")
        ow, orows = load(f"{D}/w_ours_{leg}.txt")
        if plant == "perturb" and leg == "L_60" and ow:
            f, m, v = ow[-1]
            ow[-1] = (f, m, v ^ (1 if int(m, 16) & 0xFF else 0x100))
        mc = lambda W: "\t".join(str(sum(1 for _, m, _ in W if m == k)) for k in ("000000ff", "0000ff00", "0000ffff"))
        out.append(f"masks\t{leg}\tnative\t{mc(nw)}\tours\t{mc(ow)}")
        gn = next(((fr, g.get("p1x"), g.get("a1x")) for fr, _, _, _, g in nr), None)
        go = next(((fr, g.get("p1x"), g.get("a1x")) for fr, _, _, _, g in orows), None)
        if gn:
            geoms.append(gn[1:])
            out.append(f"geom\t{leg}\t{gn[0]}\tnative\t{gn[1]}\t{gn[2]}\tours\t{go[1] if go else '-'}\t{go[2] if go else '-'}")
        if not gn or gn != go:
            fails.append(f"(c) {leg}: first write native {gn}, build {go}")
        out.append(f"leg\t{leg}\tnative\t{len(nw)}\t{sha(nw)}\tours\t{len(ow)}\t{sha(ow)}\t{'SAME' if nw == ow else 'DIFF'}")
        first, vals, frames = None, [], []
        for fr, pc, mask, v, g in nr:
            if mask != "000000ff":
                continue
            if pc == NATIVE_FIRST:
                first = (fr, g.get("node"), v)
            elif pc == NATIVE_STORE:
                if plant == "flip":
                    v ^= 1
                vals.append(v)
                frames.append(fr)
                if not (first and first[0] == fr and first[1] == g.get("node")):
                    fails.append(f"(b) {leg} f{fr}: no caller write on the same frame and node")
                    continue
                vx = int(g["a1x"], 16)
                rules = {"r0": first[2], "r1": first[2] ^ 1, "r2": (int(g["a1+0b"], 16) ^ 1) & 0xFF,
                         "r3": int(g["a6+0a"], 16), "r4": int(int(g["p1x"], 16) < vx), "neg": int(int(g["a6x"], 16) < vx)}
                per_node[int(g["node"], 16)].append((v, rules))
        out.append(f"rule5\t{leg}\t{''.join(str(x) for x in vals) or '-'}")
        last = {}
        for fr, pc, mask, v, g in orows:
            if int(mask, 16) & 0xFF:          # a byte store to +0x5D or a word store over +0x5C/+0x5D
                last[fr] = v
        if plant == "perturb" and leg == "L_60" and frames and frames[-1] in last:
            last[frames[-1]] ^= 1
        out.append(f"build5\t{leg}\t{','.join('%x' % last[f] if f in last else '-' for f in frames) or '-'}")
        if not vals:
            fails.append(f"(a) {leg}: no native rule-5 store")
    out.append(f"geometries-distinct\t{len(set(geoms))}\t{len(LEGS)}")
    bad = 0
    for node in sorted(per_node):
        c = per_node[node]
        fit = [r for r in ("r0", "r1", "r2", "r3", "r4", "neg") if all(x[1][r] == x[0] for x in c)]
        out.append(f"node\t{node:06x}\t{len(c)}\t{','.join(fit) if fit else 'NONE'}")
        bad += not fit
    out.append(f"nodes-nofit\t{bad}\t{len(per_node)}")
    print("\n".join(out))
    for f in fails:
        print(f"CHECK FAIL\t{f}")
    print("CHECK " + ("PASS" if not fails else f"FAIL ({len(fails)})"))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
