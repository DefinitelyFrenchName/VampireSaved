#!/usr/bin/env python3
"""pursuit_rigs.py — the class-0x51 PURSUIT FLAG rigs (GitHub #195, 14z-188): does the tenant's pursuit (U+LP on a
knocked-down victim) start and connect after the tenant's vs2-class-0x51 move, as on native vs2?

vs2's knockdown tail sets the victim's +0x117 (the flag the attacker-side pursuit check reads, vs2 0x26D60 / vsavj
0x27B0E) for reaction class 0x51 alone (vs2 0x239E6); our tenants' 0x51 records are remapped to 0x44, whose tail never
sets it, until #195's two hooks (build/manifest/staged/195_pursuit_mark.patch). Two rigs on tools/name_moves.py's
machinery, kept OUTSIDE the naming corpus in tests/replays/pursuit195/ (as #184's chains rigs are; name_moves.py is
not edited — the schedules are installed into name_moves.SCHEDULES at run time):
  cosmo — Pyron's Cosmo Disruption [41236 PP tap] then U+LP at +160, +170, +180, +190, +200 (14z-187's rig194), and
          the POSITIVE CONTROL: the naming rig's own throw-then-pursuit with LP, known to connect on every build;
  ifrit — Donovan's Ifrit Sword (ES) [623 PP, near] then U+LP at +72, +76, +80, +84, +88, +92 (14z-188), and the
          same control.

  python3 tools/pursuit_rigs.py gen <out dir>                       write cosmo/ifrit .rpl + .json
  python3 tools/pursuit_rigs.py rows <rig.json> <trace>              one row per event (the summary)
  python3 tools/pursuit_rigs.py compare <rig.json> <native trace> <ours trace> --expect same|gap [--zero-flag]
  python3 tools/pursuit_rigs.py p2rig <rig.rpl> <rig.json> <prologue> <out.rpl> <out.pokes>
                                                                      the rig with the tenant on P2 (below)

A row: the event, P2's +0x117 at the press frame, P2's red and white HP drops over the press window (frames relative
to the event's f0), and P1's distinct (seq, sub) states in order from the press — a pursuit that STARTS (P1 enters
seq 0xe) and one that CONNECTS (P2's HP falls) are told apart (14z-187's pursuit_sum.py, promoted).
`compare --expect same`: every row of ours equals native's (a hooked build). `--expect gap`: on every TARGET event
native's flag is 1 and ours' 0, and ours never enters seq 0xe where native does on that event — the known pre-#195
state; the CONTROL event must equal native either way. Both refuse a leg whose native side did not produce the event:
native's flag must be 1 at every press and at least one target event must START the pursuit on native (VOID, never a
pass). `--zero-flag` zeroes ours' +0x117 on every frame first (the gate's must-fire control). `--expect inert` (the lsword
rig, #200): native's flag is 1 at some target press yet no target event starts the pursuit on native, and every row of
ours equals native's with the flag set aside — the flag differs and nothing a player sees does.

`p2rig` puts a naming rig's tenant on P2 (14z-188's "Close the P2 gap first", promoted from the scratch
gen_p2rig2.py): the select lines before frame 2000 give way to <prologue> (tools/select_paths.py --rpl-prologue
0x01 <tenant cell>, the real cursor paths on the build's own wheel, P1 staying on its default cell 0x01); every
in-match p1=/p2= input swaps player, directions kept (pyron_4 pins both x before each event, so swapped pins put the
tenant on the left facing right); the rig's pokes move between the P1 and P2 blocks ($FF8400 <-> $FF8800), and the
level (6 from 2000) and RNG (0000 from 2363) pins are added for the rig's whole length."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import name_moves as nm  # noqa: E402

RIGS = {
    "cosmo": ("pyron", "c194",
              [(f"Cosmo [PP tap] then U+LP at +{o}", nm.hcf("PP") + [(o, o + 3, "U" + nm.B["LP"])], 400, "far")
               for o in (160, 170, 180, 190, 200)]
              + [("CONTROL: throw then U+LP pursuit", nm.throw_then_pursuit("LP"), 320, "near")]),
    "ifrit": ("donovan", "d195",
              [(f"Ifrit Sword (ES) then U+LP at +{o}", nm.dp("PP") + [(o, o + 3, "U" + nm.B["LP"])], 300, "near")
               for o in (72, 76, 80, 84, 88, 92)]
              + [("CONTROL: throw then U+LP pursuit", nm.throw_then_pursuit("LP"), 320, "near")]),
    # GitHub #200 (14z-188): native vs2 marks the victim at the HIT of Lightning Sword (ES) (class 0x4E) and ours does
    # not — but native clears the flag at +150 while Donovan is still in the move (to ~+155), so no pursuit starts on
    # either game; the maintainer, on the capture: "ours matches vs2 so there is no issue". Held as `--expect inert`.
    "lsword": ("donovan", "d200",
               [(f"Lightning Sword (ES) then U+LP at +{o}", nm.rdp("PP") + [(o, o + 3, "U" + nm.B["LP"])], 300, "near")
                for o in range(40, 181, 20)]
               + [("CONTROL: throw then U+LP pursuit", nm.throw_then_pursuit("LP"), 320, "near")]),
}
# the trace fields the gate adds to the parity gates' FIELDS (P2's white HP, class, seq and the word holding +0x117)
EXTRA_FIELDS = "ff8852:w:p2white,ff8854:b:p2cls,ff8806:b:p2seq,ff8916:w:p2f116"


def gen(out):
    Path(out).mkdir(parents=True, exist_ok=True)
    for rig, (tenant, part, sched) in RIGS.items():
        nm.SCHEDULES[tenant][part] = sched
        nm.METER_PARTS[tenant].add(part)       # the ES moves need a stock, as the naming rig's meter parts provide
        nm.gen(tenant, part, f"{out}/{rig}.rpl", f"{out}/{rig}.json")


def load(p):
    R, summ = {}, False
    for line in open(p):
        s = line.split()
        if s and s[0] == "F":
            R[int(s[1])] = {k: int(v) for k, v in (kv.split("=") for kv in s[2:])}
        elif "FIELDSUMMARY" in line:
            summ = True
    if not summ:
        raise SystemExit(f"FAIL: {p}: no FIELDSUMMARY — the trace did not complete")
    return R


def drops(R, fld, lo, hi, f0):
    out, prev = [], None
    for f in range(lo, hi):
        if f in R:
            v = R[f][fld]
            if prev is not None and v < prev:
                out.append(f"+{f - f0}:-{prev - v}")
            prev = v
    return out


def rows(rig_json, trace, zero_flag=False):
    R = load(trace)
    out = []
    for e in json.load(open(rig_json))["events"]:
        f0, name = e["frame"], e["name"]
        press = int(name.rsplit("+", 1)[1]) if "U+LP at +" in name else 50
        lo, hi = f0 + press, f0 + press + 140
        missing = [f for f in range(lo, hi) if f not in R]
        if missing:
            raise SystemExit(f"FAIL: {trace}: {name}: {len(missing)} frames of the window not traced")
        st, prev = [], None
        for f in range(lo, hi):
            cur = (R[f]["seq"], R[f]["sub"])
            if cur != prev:
                st.append(f"{cur[0]:x}/{cur[1]:x}")
            prev = cur
        f117 = 0 if zero_flag else R[lo]["p2f116"] & 0xFF
        out.append({"event": name, "control": name.startswith("CONTROL"), "f117": f117,
                    "red": drops(R, "p2hp", lo, hi, f0), "white": drops(R, "p2white", lo, hi, f0),
                    "states": st[:14], "pursuit": any(s.startswith("e/") for s in st)})
    return out


def fmt(r):
    return (f"{r['event']}\tf117={r['f117']}\tred={' '.join(r['red']) or '-'}\twhite={' '.join(r['white']) or '-'}"
            f"\tstates={' '.join(r['states'])}")


def compare(rig_json, nat, ours, expect, zero_flag=False):
    N, O = rows(rig_json, nat), rows(rig_json, ours, zero_flag)
    bad = []
    if expect == "inert":
        T = [n for n in N if not n["control"]]
        if not any(n["f117"] == 1 for n in T):
            bad.append("VOID: native's +0x117 is never 1 at a target press — the rig does not reach the marked window")
        if any(n["pursuit"] for n in T):
            bad.append("NOT-INERT: a target event starts the pursuit on native — the flag is acted on")
        for n, o in zip(N, O):
            a, b = dict(n, f117=None), dict(o, f117=None)
            if (fmt(n) if n["control"] else fmt(a)) != (fmt(o) if n["control"] else fmt(b)):
                bad.append(f"DIFF {n['event']}\n    native {fmt(n)}\n    ours   {fmt(o)}")
        for n, o in zip(N, O):
            print(f"  native  {fmt(n)}\n  ours    {fmt(o)}")
        return bad
    # VOID first: the native leg must have produced the events
    if any(n["f117"] != 1 for n in N):
        bad.append("VOID: native's +0x117 is not 1 at every press — the rig did not knock the victim down natively")
    if not any(n["pursuit"] for n in N if not n["control"]):
        bad.append("VOID: no target event starts the pursuit on native — the rig does not exercise the flag")
    for n, o in zip(N, O):
        if n["control"] or expect == "same":
            if fmt(n) != fmt(o):
                bad.append(f"DIFF {n['event']}\n    native {fmt(n)}\n    ours   {fmt(o)}")
        else:  # gap: the known pre-#195 state on every target event
            if not (o["f117"] == 0 and not (n["pursuit"] and o["pursuit"])):
                bad.append(f"NOT-GAP {n['event']}\n    native {fmt(n)}\n    ours   {fmt(o)}")
    for n, o in zip(N, O):
        print(f"  native  {fmt(n)}\n  ours    {fmt(o)}")
    return bad


def p2rig(src_rpl, src_json, prologue, out_rpl, out_pokes):
    import re
    out = []
    for line in open(src_rpl).read().splitlines():
        s = line.split("#")[0].strip()
        if not s:
            continue
        m = re.match(r"^(\d+)(?:-(\d+))?\s+(p1|p2)=(\S+)$", s)
        if m and int(m.group(1)) < 2000:
            continue
        if m:
            who = "p2" if m.group(3) == "p1" else "p1"
            out.append((int(m.group(1)), f"{m.group(1)}{'-' + m.group(2) if m.group(2) else ''} {who}={m.group(4)}"))
        else:
            f = re.match(r"^(\d+)", s)
            out.append((int(f.group(1)) if f else 0, s))
    head = [t_l[1] for t_l in out if t_l[0] < 2000]
    body = sorted([t_l for t_l in out if t_l[0] >= 2000], key=lambda x: x[0])
    pro = open(prologue).read()
    open(out_rpl, "w").write(f"# {Path(src_rpl).stem} with the tenant on P2 (tools/pursuit_rigs.py p2rig; DO NOT hand-edit)\n"
                             + "\n".join(head) + "\n" + pro + "\n".join(l for _, l in body) + "\n")
    J = json.load(open(src_json))
    def swap(pk):
        f, a, v = pk.split(":")
        ai = int(a, 16)
        if 0xFF8400 <= ai < 0xFF8800:
            ai += 0x400
        elif 0xFF8800 <= ai < 0xFF8C00:
            ai -= 0x400
        return f"{f}:{ai:06x}:{v}"
    pokes = [swap(pk) for pk in J["pokes"]]
    pokes += [f"{f}:ff80d4:0000" for f in range(2363, J["frames"])] + [f"{f}:ff8116:06" for f in range(2000, J["frames"])]
    open(out_pokes, "w").write(";".join(pokes))


def main(argv):
    if not argv:
        raise SystemExit(__doc__)
    cmd = argv[0]
    if cmd == "gen":
        gen(argv[1])
    elif cmd == "rows":
        for r in rows(argv[1], argv[2]):
            print(fmt(r))
    elif cmd == "p2rig":
        p2rig(*argv[1:6])
    elif cmd == "compare":
        expect = argv[argv.index("--expect") + 1]
        assert expect in ("same", "gap", "inert"), expect
        bad = compare(argv[1], argv[2], argv[3], expect, "--zero-flag" in argv)
        for b in bad:
            print(f"  FAIL  {b}")
        print(f"{'FAIL' if bad else 'OK'}: {len(bad)} finding(s), expect={expect}")
        sys.exit(1 if bad else 0)
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
