#!/usr/bin/env python3
"""facing_hook_ab.py — #159's facing hook split into its CYCLES and its LOGIC (GitHub #186, 14z-186).

#159 routes vsavj's facing resolver's fall-through (`eor.b d0,$5d(a1); bra.b`, CPU:$01886C) through a
`jmp` to a thunk: `cmpi.b #5,d0; beq` to vs2's rule-5 branch, else the original eor and `rts`. Two
side moves came with it at the M21 freeze (Pyron's mash ring stream, 110_don_arcade_mash's defense
reads). This tool builds two probe variants of a merged build FROM ITS OWN GENERATED patch.json, so
their placement is the build's, and reads the gate's streams:

  ctl      — the patch unfiltered: its program members must equal the build's (the path's control)
  logicoff — the thunk's `cmpi.b #5,d0` made `cmpi.b #$FF,d0`: the hook runs (its cycles), rule 5 is
             never taken
  unhooked — the site op dropped: the thunk placed where the build places it, the site pristine

Subcommands:
  variants <build dir> <out dir> <pristine vsavj.zip> [--inert]
      --inert builds logicoff WITHOUT its edit (the variant-inert control's input)
  check <work dir> <expected tsv> [--control NAME] [--freeze]
      reads the legs tests/audit_facing_hook_ab.sh ran and prints the checks; exit 1 on a failure
"""
import argparse, json, os, re, shutil, subprocess, sys, zipfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE = 0x1886C
PRG_MEMBERS = [f"vm3j.{m}" for m in ("03d", "04d", "05a", "06b", "07b", "08a", "09b", "10b")]
# the +0x5D byte writers on the write tap of +0x5C: the resolver's pre-write, the fall-through eor
# (vanilla site, or the thunk's eor at thunk+6), the rule-5 store (thunk+0x16)
PRE_PC = "01884e"


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode:
        sys.exit(f"FAIL: {' '.join(cmd)}\n{r.stdout[-800:]}{r.stderr[-800:]}")
    return r.stdout


def opview(zip_path, out):
    run([sys.executable, f"{REPO}/tools/cps2_decrypt.py", zip_path, out])
    return open(out, "rb").read()


def thunk_ops(ops):
    st = [o for o in ops if o.get("op") == "code" and int(o["addr"], 16) == SITE]
    if len(st) != 1 or not st[0]["hex"].lower().startswith("4ef9") or len(st[0]["hex"]) != 12:
        sys.exit("FAIL: the build's patch carries no single `jmp abs.l` op at CPU:$01886C (#159's hook)")
    tgt = int(st[0]["hex"][4:], 16)
    th = [o for o in ops if o.get("op") == "code" and int(o["addr"], 16) == tgt]
    if len(th) != 1 or not th[0]["hex"].lower().startswith("0c0000056706"):
        sys.exit(f"FAIL: the op at the hook's target {tgt:#x} is not #159's thunk (cmpi.b #5,d0; beq.s)")
    return st[0], th[0], tgt


def variants(a):
    build, out = os.path.abspath(a.build), os.path.abspath(a.out)
    spec = json.load(open(f"{build}/patch/patch.json"))
    _, _, tgt = thunk_ops(spec["ops"])
    os.makedirs(out, exist_ok=True)
    pristine = opview(a.vsavj, f"{out}/vsavj_op.bin")
    print(f"hook: CPU:$01886C jmp -> thunk CPU:${tgt:06X}; rule-5 store at CPU:${tgt + 0x16:06X}")
    for v in ("ctl", "logicoff", "unhooked"):
        d = f"{out}/v_{v}"
        shutil.rmtree(d, ignore_errors=True)
        shutil.copytree(f"{build}/patch", f"{d}/patch")
        os.makedirs(f"{d}/rompath")
        p = json.load(open(f"{d}/patch/patch.json"))
        st, th, _ = thunk_ops(p["ops"])
        if v == "logicoff" and not a.inert:
            th["hex"] = "0c0000ff" + th["hex"][8:]
        elif v == "unhooked":
            p["ops"] = [o for o in p["ops"] if o is not st]
        json.dump(p, open(f"{d}/patch/patch.json", "w"))
        run([sys.executable, f"{REPO}/tools/patch_prg.py", a.vsavj, f"{d}/prg", "--patch", f"{d}/patch/patch.json"])
        zi = zipfile.ZipFile(f"{build}/rompath/vsavjw.zip")
        zo = zipfile.ZipFile(f"{d}/rompath/vsavjw.zip", "w", zipfile.ZIP_DEFLATED)
        for i in zi.infolist():
            zo.writestr(i.filename, open(f"{d}/prg/{i.filename}", "rb").read()
                        if i.filename in PRG_MEMBERS else zi.read(i.filename))
        zo.close()
        view = opview(f"{d}/rompath/vsavjw.zip", f"{d}/op.bin")
        site, thunk = view[SITE:SITE + 6].hex(), view[tgt:tgt + 6].hex()
        same = [m for m in PRG_MEMBERS if open(f"{d}/prg/{m}", "rb").read() == zi.read(m)]
        print(f"variant {v}: site {site} thunk-head {thunk} program members equal to the build's "
              f"{len(same)}/{len(PRG_MEMBERS)}")
        json.dump({"site": site, "thunk": thunk, "same": same, "pristine_site": pristine[SITE:SITE + 6].hex(),
                   "tgt": tgt}, open(f"{d}/variant.json", "w"))


def ring(path):
    out, end = [], False
    for ln in open(path):
        m = re.match(r"f(\d+) id ([0-9a-f]{4}) pc", ln)
        if m and int(m.group(2), 16) not in (0, 0xFFFF):
            out.append((int(m.group(1)), m.group(2)))
        elif ln.startswith("END"):
            end = True
    return out, end


def tap(path, tgt):
    """(+0x5D writes, defense reads, END seen) from a read_tap.lua log."""
    names = {PRE_PC: "PRE", "01886c": "FT", f"{tgt + 6:06x}": "FT", f"{tgt + 0x16:06x}": "R5"}
    w, r, end = [], [], False
    for ln in open(path):
        p = ln.split()
        if not p:
            continue
        if p[0] == "END":
            end = True
        elif p[0] == "W" and p[5] in ("ff845c", "ff885c") and p[9] == "000000ff":
            w.append((int(p[1]), names.get(p[3], "PC" + p[3]), p[5], p[7]))
        elif p[0] == "R":
            r.append(tuple(p[1:]))
    return w, r, end


def agree(a, b):
    n = 0
    for x, y in zip(a, b):
        if x != y:
            break
        n += 1
    return n


def check(a):
    W, ctl = a.work, a.control
    fails, fired = [], {}
    def ok(m): print(f"  ok    {m}")
    def bad(m): print(f"  FAIL  {m}"); fails.append(m)
    V = {v: json.load(open(f"{W}/v_{v}/variant.json")) for v in ("ctl", "logicoff", "unhooked")}
    tgt = V["ctl"]["tgt"]
    print("== 1. the variants (decrypted opcode views)")
    (ok if len(V["ctl"]["same"]) == 8 else bad)(f"ctl: {len(V['ctl']['same'])}/8 program members equal the build's (the variant path reproduces it)")
    lo_ok = V["logicoff"]["thunk"].startswith("0c0000ff")
    ip = f"{W}/inert/v_logicoff/variant.json"   # the variant-inert control's input: logicoff built WITHOUT its edit
    if os.path.exists(ip):
        fired["variant-inert"] = not json.load(open(ip))["thunk"].startswith("0c0000ff")
    (ok if lo_ok else bad)(f"logicoff: thunk head {V['logicoff']['thunk']} reads cmpi.b #$FF,d0")
    (ok if V["logicoff"]["site"] == V["ctl"]["site"] else bad)(f"logicoff: site {V['logicoff']['site']} is the build's hook")
    (ok if V["unhooked"]["site"] == V["unhooked"]["pristine_site"] else bad)(
        f"unhooked: site {V['unhooked']['site']} equals pristine vsavj's {V['unhooked']['pristine_site']}")
    (ok if V["unhooked"]["thunk"] == V["ctl"]["thunk"] else bad)(f"unhooked: the thunk still placed ({V['unhooked']['thunk']})")
    exp = {}
    if os.path.exists(a.expected):
        for ln in open(a.expected):
            if ln.strip() and not ln.startswith("#"):
                k, v = ln.rstrip("\n").split("\t")
                exp[k] = v
    got = {}
    print("== 2. Pyron's mash ring stream against solo (tests/audit_pyron_ring.sh's comparison)")
    s, s_end = ring(f"{W}/ring_solo/ring.txt")
    streams = {}
    for v in ("build", "logicoff", "unhooked"):
        m, m_end = ring(f"{W}/ring_{v}/ring.txt")
        if not (m_end and s_end):
            bad(f"ring {v}: a run reached no END line"); continue
        if v == "logicoff" and ctl == "stream-shifted":
            k = len(m) // 2; m = m[:k] + [(m[k][0] - 1, m[k][1])] + m[k + 1:]
        streams[v] = m
        k = agree(m, s)
        got[f"ring_{v}"] = "whole" if k == len(m) == len(s) else f"f{m[k][0]}"
    lm = streams.get("logicoff", [])
    if lm:
        k = len(lm) // 2
        sh = lm[:k] + [(lm[k][0] - 1, lm[k][1])] + lm[k + 1:]
        fired["stream-shifted"] = agree(sh, s) < len(sh)
    print("== 3. the facing writes (+0x5D) and the defense reads")
    W5 = {}
    for rp in ("mash", "arc110"):
        for v in ("build", "logicoff", "unhooked"):
            w, r, end = tap(f"{W}/tap_{rp}_{v}/t.tap", tgt)
            if not end:
                bad(f"tap {rp} {v}: no END line")
            W5[(rp, v)] = (w, r)
    mash_b = list(W5[("mash", "build")][0])
    planted = list(mash_b)
    fts = [i for i, e in enumerate(planted) if e[1] == "FT"]
    if fts:
        i = fts[len(fts) // 2]; planted[i] = (planted[i][0], "R5") + planted[i][2:]
    fired["r5-planted"] = sum(1 for e in planted if e[1] == "R5") > 0
    if ctl == "r5-planted":
        W5[("mash", "build")] = (planted, W5[("mash", "build")][1])
    for rp in ("mash", "arc110"):
        for v in ("build", "logicoff", "unhooked"):
            w = W5[(rp, v)][0]
            r5 = [e for e in w if e[1] == "R5"]
            got[f"r5_{rp}_{v}"] = f"{len(r5)}" + (f"@f{r5[0][0]}" if r5 else "")
            got[f"writes_{rp}_{v}"] = str(len(w))
        for x, y in (("logicoff", "build"), ("unhooked", "build"), ("logicoff", "unhooked")):
            wa, wb = W5[(rp, x)][0], W5[(rp, y)][0]
            k = agree(wa, wb)
            got[f"facing_{rp}_{x}_vs_{y}"] = "same" if k == len(wa) == len(wb) else \
                f"f{wb[k][0]}:{wb[k][1]}" if k < len(wb) else f"f{wa[k][0]}:{wa[k][1]}"
    dr = {v: W5[("arc110", v)][1] for v in ("build", "logicoff", "unhooked")}
    un = dr["unhooked"]
    if un:
        dropped = un[:len(un) // 2] + un[len(un) // 2 + 1:]
        fired["read-dropped"] = not (agree(dr["logicoff"], dropped) == len(dropped) == len(dr["logicoff"]))
        if ctl == "read-dropped":
            dr["unhooked"] = dropped
    for x, y in (("logicoff", "unhooked"), ("build", "unhooked")):
        k = agree(dr[x], dr[y])
        got[f"reads_arc110_{x}_vs_{y}"] = "same" if k == len(dr[x]) == len(dr[y]) else \
            f"{k}:f{dr[x][k][0] if k < len(dr[x]) else '-'}/f{dr[y][k][0] if k < len(dr[y]) else '-'}"
    got["reads_arc110_counts"] = "/".join(str(len(dr[v])) for v in ("build", "logicoff", "unhooked"))
    for k in sorted(got):
        print(f"  {k}\t{got[k]}")
    # THE READING the frozen rows encode (checked here, not only frozen):
    mash_cycles = (got.get("ring_build") == "whole" and got.get("ring_logicoff") == "whole"
                   and got.get("ring_unhooked") != "whole" and got.get("r5_mash_build") == "0")
    arc_logic = (got.get("reads_arc110_logicoff_vs_unhooked") == "same"
                 and got.get("reads_arc110_build_vs_unhooked") != "same"
                 and got.get("facing_arc110_logicoff_vs_unhooked") == "same"
                 and got.get("facing_arc110_unhooked_vs_build", "").endswith(":R5")
                 and not got.get("r5_arc110_build", "0").startswith("0"))
    print("== 4. the reading")
    (ok if mash_cycles else bad)("Pyron mash: the HOOK's execution moves it (build and logicoff agree with solo whole-run, "
                                 "unhooked diverges; rule 5 never fires on it)")
    (ok if arc_logic else bad)("110_don_arcade_mash: the RULE-5 LOGIC moves it (logicoff reads what unhooked reads; the build's "
                               "first facing difference from them is a rule-5 store)")
    print("== 5. the frozen expectation")
    if a.freeze:
        with open(a.expected, "w") as f:
            f.write("# tests/audit_facing_hook_ab.sh — frozen by FREEZE=1 (tools/facing_hook_ab.py check). key<TAB>value\n")
            for k in sorted(got):
                f.write(f"{k}\t{got[k]}\n")
        print(f"  FROZEN {a.expected} ({len(got)} rows)")
    elif not exp:
        bad(f"no expectation at {a.expected} (FREEZE=1 after review)")
    else:
        diff = [k for k in sorted(set(exp) | set(got)) if exp.get(k) != got.get(k)]
        for k in diff:
            bad(f"{k}: frozen {exp.get(k)} got {got.get(k)}")
        if not diff:
            ok(f"all {len(got)} rows equal the frozen expectation")
    print("== 6. controls")
    for n in ("variant-inert", "stream-shifted", "read-dropped", "r5-planted"):
        if fired.get(n):
            print(f"CONTROL FIRED: {n} — the perturbed copy is caught")
        else:
            print(f"CONTROL DEAD: {n} — the perturbed copy was not caught"); fails.append(n)
    return 1 if fails else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sp = ap.add_subparsers(dest="cmd", required=True)
    v = sp.add_parser("variants"); v.add_argument("build"); v.add_argument("out"); v.add_argument("vsavj")
    v.add_argument("--inert", action="store_true")
    c = sp.add_parser("check"); c.add_argument("work"); c.add_argument("expected")
    c.add_argument("--control", default=""); c.add_argument("--freeze", action="store_true")
    a = ap.parse_args()
    if a.cmd == "variants":
        variants(a)
    else:
        sys.exit(check(a))
