#!/usr/bin/env python3
"""victim_parity.py — THE TENANT AS THE VICTIM, ours vs native: the reducer of
tests/audit_victim_parity.sh (14z-181, GitHub #136).

The victim rigs (tools/name_moves.py `<tenant>_victim`: P1 Victor attacks P2 the
tenant with every contact class) had one leg — native vs2 — frozen by
tests/test_reactions.sh as the phase-3 reaction map. This reducer gives them the
OURS leg and compares, per contact, what tools/reaction_map.py reads on each:
the victim's class byte, freeze, chain path and frames back to a stand chain.
Our node pointers are TRANSLATED into the native address space through the
build's placements.json (tools/move_parity.translator) before the chain
decoder — the same trick tests/audit_move_parity.sh uses — so both legs are
read by ONE decoder over the tenant's vs2 extract.

Modes (each prints to stdout; a refusal is a non-zero exit with FAIL: on stdout):
  translate <trace> <placements.json> <tenant> <out>       rewrite p2node ours -> native space
  contacts  <schedule.json> <trace> <chains_dir>           reaction_map lines WITH the contact frame (@f)
  compare   <tenant> <part> <native lines> <ours lines> [--events <schedule.json> --p1 <native p1check> <ours p1check>]
                                                           the ev rows (SAME | DIFFER(fields)); frames printed, not
                                                           compared; `attacker=` names the differing-data Victor chains
                                                           that ran inside the row's EVENT on either leg, else `-`
  p1check   <trace> <image> <layout> <tenant id> --same <victor_same.json> [--from F]
                                                           P1 is Victor (0x03), never in a REACTION chain (b/c) whose
                                                           data differs between the games; his differing ATTACK
                                                           chains (a/a2/proj) are printed as P1DIFF spans; P2 is the tenant
  pinscheck <schedule pokes file> <lines>                  refuse a SCHEDULE poke inside a contact window [f, f+len)
  poked     <part> <ours-or-native lines> <frozen reactions file>   same/differ counts against test_reactions' frozen lines
                                                           (the first label's @entry index masked: the pre-contact stance, not the reaction)
  plant-p1  <trace> <image> <layout> <out> --same <json>   perturbed copy: one P1 node set to a differing Victor reaction chain
  drop-first <lines in> <lines out>                        perturbed copy: the first contact line removed
  swap-label <lines in> <lines out> <native p1check> <ours p1check> --events <schedule.json> [--timing]
                                                           perturbed copy: one chain label changed (or, --timing, len +3) on the first
                                                           line whose event holds a differing attacker span (the tenant-planted /
                                                           timing-planted controls' input)
  chains-plant <extract dir> <our data view> <placements.json> <tenant> <out image>
                                                           perturbed copy of our data view: one valid chain's first node dur +1
  chains-identical <extract dir> <our data view> <placements.json> <tenant>
                                                           the tenant's a/a2/b/c chains decode to the SAME SHAPES (node
                                                           count, dur/flags/sfx/hbA per node) from our build as from the
                                                           vs2 extract — the ported bytes premise, measured

WHAT IS COMPARED per contact: cls, frz, path (up to 8 chain labels), len. The
contact FRAME is printed on both legs and NOT compared (the parity gates' rule
since #168: a phase, not a behaviour). The ATTACKER is VS's Victor on our leg and
VS2's on the native one, and 18 of his a2 chains, 3 proj and every b/c reaction
chain differ between the games (audit_same_data_p2, id 0x03, run by the gate on
the two data views): p1check refuses a leg where he entered a differing REACTION
chain (he was hit — not a victim rig) and reports every span of a differing
ATTACK chain, and compare() attributes each contact row to the differing chains
that ran inside its event (`attacker=`), so a DIFFER row there is the two
Victors, not the tenant — 14z-181 measured the throw family that way: his throw
start a2:0x38 is 25 data frames on vs2 and 24 on vsavj (its first node dur 2 vs
1), so five of its six throw hits land one frame earlier on our leg (the third
on the same frame) and the tenant's release chains read `len` one frame longer.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import reaction_map          # noqa: E402
import move_parity           # noqa: E402

VICTOR = 0x03
ATTACK_TABLES = ("a", "a2", "proj")   # the attacker's own chains; b and c are his REACTION sets


def load_trace(path):
    out = {}
    for line in open(path):
        f = line.split()
        if len(f) >= 3 and f[0] == "F":
            out[int(f[1])] = {k: int(v) for k, v in (kv.split("=") for kv in f[2:])}
    return out


def write_trace(rows, path):
    with open(path, "w") as fo:
        for f in sorted(rows):
            fo.write("F %d %s\n" % (f, " ".join("%s=%d" % kv for kv in rows[f].items())))


def translate(trace, placements, tenant, out):
    tr, (dst, src, ln) = move_parity.translator(placements, tenant)
    rows = load_trace(trace)
    moved = 0
    for f in rows:
        v = rows[f]["p2node"] & 0xFFFFFFFF
        t = tr(v)
        if t != v:
            moved += 1
        rows[f]["p2node"] = t
    write_trace(rows, out)
    print("translated %d of %d frames (anim region dst=%#x src=%#x len=%#x)" % (moved, len(rows), dst, src, ln))


def parse_line(line):
    """'<part>\\t<event>\\tcls=..\\tfrz=..\\t<path>\\tlen=..[\\t@f]' -> dict"""
    f = line.rstrip("\n").split("\t")
    d = {"part": f[0], "event": f[1], "cls": f[2], "frz": f[3], "path": f[4], "len": f[5], "frame": None}
    if len(f) > 6 and f[6].startswith("@"):
        d["frame"] = int(f[6][1:])
    return d


def p1diff_spans(path):
    out = []
    for l in open(path):
        if l.startswith("P1DIFF: "):
            lab, fr = l.split()[1], l.split()[2]
            a, b = fr[1:].split("-")
            out.append((lab, int(a), int(b)))
    return out


TIMING_FIELDS = {"len", "frz"}   # what a differing attacker chain's LENGTH can move: the contact's frame and so
                                 # the reaction's length and the freeze sampled at it — never which chain the VICTIM runs


def explained(a, b, delta):
    """is the TIMING difference between the native line `a` and ours `b` exactly what the
    attacker's own shift can produce? `delta` = the differing attacker chain's length on
    native minus ours (Victor's a2:0x38: 9 - 8 = +1 data frame). The contact may land `delta`
    earlier on ours or on the same frame; the RETURN (contact + len, the stand) may come
    `delta` earlier or on the same frame — a victim whose thrown chain holds until the
    release follows the shift (Donovan, stand 4440 native / 4439 ours), one whose chain is
    a fixed length from the grab does not (Phobos, 4439 on both) — and the freeze sampled at
    the contact may differ by at most |delta|. Any other size is NOT the attacker's
    (rule-checker run 2026-09-25-159 Q1/Q4)."""
    if a["frame"] is None or b["frame"] is None or delta is None:
        return False
    cs = a["frame"] - b["frame"]
    try:
        la, lb = int(a["len"][4:]), int(b["len"][4:])
    except ValueError:
        return False
    rs = (a["frame"] + la) - (b["frame"] + lb)
    fz = abs(int(a["frz"][4:]) - int(b["frz"][4:]))
    return cs in (0, delta) and rs in (0, delta) and fz <= abs(delta)


def attributed(diff, att, a=None, b=None, delta=None):
    """which side a DIFFER row is charged to (rule-checker run 2026-09-25-158 Q4: the first form
    stamped every row inside an attacker-differing event as the attacker's, and absorbed Pyron's
    b:0x19/b:0x03 label differences behind the throw; run -159 Q4: a timing difference of ANY
    size was then charged to the attacker): a TIMING-only difference (len, frz) inside an event
    where a differing attacker chain ran is the ATTACKER's only when the attacker's own shift
    explains it (explained()); a difference in cls or in the chain PATH is the TENANT's (the
    victim's own reaction), whatever ran beside it; a row with both is split —
    `attacker+tenant` — when its timing part is explained, else the tenant's."""
    if not diff:
        return "-"
    timing = set(diff) & TIMING_FIELDS; other = set(diff) - TIMING_FIELDS
    if att != "-" and timing and explained(a, b, delta):
        return "attacker" if not other else "attacker+tenant"
    return "tenant"


def attacker_for(frame, events, spans):
    """the differing attacker chains that ran inside the EVENT holding `frame`
    ([event.frame, next event.frame)), or '-' — a CO-OCCURRENCE, which attributed() turns into a
    charge only for the timing fields"""
    lo, hi = None, None
    for k, e in enumerate(events):
        if e["frame"] <= frame:
            lo = e["frame"]; hi = events[k + 1]["frame"] if k + 1 < len(events) else 10 ** 9
    if lo is None:
        return "-"
    hit = sorted({lab for lab, a, b in spans if a < hi and b >= lo})
    return ",".join(hit) if hit else "-"


def span_delta(spans_native, spans_ours):
    """the attacker's shift: for each differing chain label, native span length minus ours (the
    first span of each); None when the two legs do not both carry it"""
    out = {}
    for lab, a, b in spans_native:
        out.setdefault(lab, [None, None])[0] = b - a + 1
    for lab, a, b in spans_ours:
        out.setdefault(lab, [None, None])[1] = b - a + 1
    return {lab: (v[0] - v[1]) if None not in v else None for lab, v in out.items()}


def compare(tenant, part, native_path, ours_path, events=None, spans=(), deltas=None):
    n = [parse_line(l) for l in open(native_path) if l.strip()]
    o = [parse_line(l) for l in open(ours_path) if l.strip()]
    rows = []
    for k in range(min(len(n), len(o))):
        a, b = n[k], o[k]
        diff = [key for key in ("cls", "frz", "path", "len") if a[key] != b[key]]
        if a["event"] != b["event"]:
            diff.insert(0, "event")
        verdict = "SAME" if not diff else "DIFFER(%s)" % ",".join(diff)
        fmt = lambda d: "%s,%s,%s,%s@%s" % (d["cls"], d["frz"], d["len"], d["path"], d["frame"])
        att = attacker_for(a["frame"] if a["frame"] is not None else -1, events or [], spans) if events else "-"
        # the attacker's shift for the charge: the ONE differing chain's delta (a row with several is not charged)
        labs = att.split(",") if att != "-" else []
        delta = (deltas or {}).get(labs[0]) if len(labs) == 1 else None
        rows.append("ev\t%s\t%s\t%d\t%s\t%s\tnative=%s\tours=%s\tattacker=%s\tattributed=%s" % (tenant, part, k, a["event"], verdict, fmt(a), fmt(b), att, attributed(diff, att, a, b, delta)))
    if len(n) != len(o):
        rows.append("ev\t%s\t%s\t-\tcontacts\tDIFFER(contacts)\tnative=%d\tours=%d\tattacker=-\tattributed=tenant" % (tenant, part, len(n), len(o)))
    return rows


def victor_differs(same_json):
    """Victor's chains whose data differs between vsavj and vsav2, per table, from
    tools/audit_same_data_p2.py's JSON run on the two data views by the gate itself
    (the frozen tests/expected/same_data_p2.tsv lists a/b/c only — a2, where his
    throw start a2:0x38 differs, is a count there; 14z-181)."""
    d = json.load(open(same_json))["0x03"]["anim_seqs_diff"]
    out = set()
    for tab, v in d.items():
        for k in ("differ", "invalid_one_side", "only_vsavj", "only_vsav2"):
            out |= {(tab, int(x, 16)) for x in v.get(k, [])}
    return out


def p1check(trace, image, layout, tenant_id, first, same_json):
    t = load_trace(trace)
    frames = sorted(f for f in t if f >= first)
    if not frames:
        return False, ["FAIL: no sampled frame at or after %d" % first]
    f0 = frames[0]
    lines = ["p1 id at f%d: %#04x (want 0x03); p2 id: %#04x (want %#04x)" % (f0, t[f0]["id"], t[f0]["p2id"], tenant_id)]
    ok = t[f0]["id"] == VICTOR and t[f0]["p2id"] == tenant_id
    idx = move_parity.p2_chain_index(image, layout, VICTOR)
    differs = victor_differs(same_json)
    seen, unmapped, spans, cur = {}, 0, [], None
    for f in frames:
        n = t[f]["node"] & 0xFFFFFFFF
        k = idx.get(n)
        if k is None:
            if n:
                unmapped += 1
            continue
        seen[k] = seen.get(k, 0) + 1
        if k != cur:
            spans.append([k, f, f]); cur = k
        else:
            spans[-1][2] = f
    lines.append("p1 (Victor) chains entered over %d frames (%d unmapped non-zero nodes): %s" % (
        len(frames), unmapped, " ".join("%s:0x%02x=%d" % (k[0], k[1], v) for k, v in sorted(seen.items()))))
    lines.append("p1 differing-data set (audit_same_data_p2 on the two data views, id 0x03, %d chains): %s" % (
        len(differs), " ".join("%s:0x%02x" % k for k in sorted(differs))))
    for k in sorted(seen):
        if k in differs and k[0] not in ATTACK_TABLES:
            ok = False
            lines.append("FAIL: P1 entered %s:0x%02x on %d frame(s) — a Victor REACTION chain whose data differs between the games (the attacker was hit)" % (k[0], k[1], seen[k]))
    # an ATTACK chain of his whose data differs is not a red: it is REPORTED per span, and the
    # gate attributes every contact row of the event it ran in to it (the two Victors, not the tenant)
    for k, a, b in spans:
        if k in differs and k[0] in ATTACK_TABLES:
            lines.append("P1DIFF: %s:0x%02x f%d-%d" % (k[0], k[1], a, b))
    if unmapped > 0.05 * len(frames):
        ok = False
        lines.append("FAIL: %d of %d frames hold a P1 node outside Victor's decoded graph — the image or layout is not this leg's" % (unmapped, len(frames)))
    return ok, lines


def plant_p1(trace, image, layout, out, same_json):
    """one frame's P1 node replaced by the entry node of the first differing Victor REACTION chain"""
    idx = move_parity.p2_chain_index(image, layout, VICTOR)
    never = {k for k in victor_differs(same_json) if k[0] not in ATTACK_TABLES}
    target = None
    for addr, k in sorted(idx.items()):
        if k in never:
            target = addr
            break
    if target is None:
        raise SystemExit("FAIL: no node of a differing Victor chain in the index")
    rows = load_trace(trace)
    f = sorted(rows)[len(rows) // 2]
    rows[f]["node"] = target
    write_trace(rows, out)
    print("planted node %#x (%s:0x%02x) at f%d" % (target, idx[target][0], idx[target][1], f))


def pinscheck(pokes_path, lines_path):
    pokes = [p for p in open(pokes_path).read().replace("\n", ";").split(";") if p]
    frames = sorted({int(p.split(":")[0]) for p in pokes})
    bad = []
    for l in open(lines_path):
        if not l.strip():
            continue
        d = parse_line(l)
        if d["frame"] is None or d["len"] == "len=None":
            continue
        lo = d["frame"]; hi = lo + int(d["len"][4:])
        inside = [f for f in frames if lo <= f < hi]
        if inside:
            bad.append("%s %s [%d,%d): pokes at %s" % (d["part"], d["event"], lo, hi, ",".join(map(str, inside))))
    print("schedule pokes: %d frames; contact windows checked: %d" % (len(frames), sum(1 for l in open(lines_path) if l.strip())))
    for b in bad:
        print("FAIL: a schedule poke inside a compared window — " + b)
    return not bad


def mask_first(path):
    labs = path.split(" ")
    if labs and "@" in labs[0]:
        labs[0] = labs[0].split("@")[0] + "@*"
    return " ".join(labs)


def poked(part, lines_path, frozen_path):
    """the leg's lines against test_reactions' frozen (poked-pick, every-400 HP pins, no level/RNG pin) lines of the same part"""
    mine = [parse_line(l) for l in open(lines_path) if l.strip()]
    froz = [parse_line(l) for l in open(frozen_path) if l.strip() and l.split("\t")[0] == part]
    same = differ = 0
    out = []
    for k in range(min(len(mine), len(froz))):
        a, b = froz[k], mine[k]
        # the FIRST label is the chain P2 was already ON at the contact frame (a stand or the block
        # stance) and its @index is how far into it the contact registered — the rig's spacing, not
        # the reaction (14z-181: Pyron part 2 read a:0x13@8 for the frozen @7 on three lines, every
        # reaction field equal); the entry index is masked on that label only
        # the frozen lines keep 8 labels (reaction_map's default); this leg's keep 64 — cut to compare
        a = dict(a, path=mask_first(a["path"])); b = dict(b, path=mask_first(" ".join(b["path"].split(" ")[:8])))
        d = [key for key in ("event", "cls", "frz", "path", "len") if a[key] != b[key]]
        if d:
            differ += 1; out.append("  differs %s #%d %s: %s (frozen %s,%s,%s,%s | this leg %s,%s,%s,%s)" % (
                part, k, a["event"], ",".join(d), a["cls"], a["frz"], a["len"], a["path"], b["cls"], b["frz"], b["len"], b["path"]))
        else:
            same += 1
    if len(mine) != len(froz):
        out.append("  contacts: frozen %d, this leg %d" % (len(froz), len(mine)))
    print("poked\t%s\tsame=%d\tdiffer=%d\tcontacts=%d/%d" % (part, same, differ, len(froz), len(mine)))
    for o in out:
        print(o)


def chains_identical(extract_dir, ours_image, placements, tenant, tables=("a", "a2", "b", "c")):
    """Are the tenant's anim chains the SAME SHAPE on our build as in the vs2 extract
    the decoder reads? tools/anim_nodes.py walks each index table on both images —
    the extract at its native base, our data view at the placed base (the index
    pointer translated) — and every chain's node count and per-node dur/flags/sfx/hbA
    are compared (pointers are relocated by the port, so they are not). Rule-checker
    run 2026-09-25-156 Q1: "the engine's choice, not the ported bytes" needs this
    measured, not assumed."""
    import subprocess, tempfile
    rj = json.load(open(os.path.join(extract_dir, "regions.json"))); r = rj["regions"]["anim"]
    ptr = {v["table"]: int(v["ptr"], 16) for v in rj["values"] if v["table"].startswith("anim_index")}
    regs = json.load(open(placements))["regions"]
    key = "anim" if tenant == "donovan" else "anim@" + tenant
    dst, src, ln = regs[key]["dst"], regs[key]["src"], regs[key]["len"]
    assert (src, ln) == (r["src"], r["len"]), "the placement's anim region is not the extract's (%#x/%#x vs %#x/%#x)" % (src, ln, r["src"], r["len"])
    tmp = tempfile.mkdtemp()
    # our decoder sees exactly the placed REGION, as the native one sees region_anim.bin: a chain
    # whose nodes link past the region decodes short on both (the first form read the whole data
    # view on ours and 76 of Phobos's c chains "differed" by the bytes past the region's end)
    with open(ours_image, "rb") as fh:
        fh.seek(dst); ours_region = fh.read(ln)
    ours_slice = os.path.join(tmp, "ours_region_anim.bin")
    open(ours_slice, "wb").write(ours_region)
    lines, ok = [], True
    for name in tables:
        out = {}
        for side, img, base, tab in (("native", os.path.join(extract_dir, "region_anim.bin"), src, ptr["anim_index_" + name]),
                                     ("ours", ours_slice, dst, ptr["anim_index_" + name] - src + dst)):
            j = os.path.join(tmp, "%s_%s.json" % (side, name))
            end = (src if side == "native" else dst) + ln
            subprocess.check_call(["python3", os.path.join(HERE, "anim_nodes.py"), img, "--base", hex(base), "--table", hex(tab),
                                   "--name", name, "--end", hex(end), "--json", j], stdout=subprocess.DEVNULL)
            ch = json.load(open(j))["chains"]
            # tools/audit_same_data_p2.py's rule: a walk that ran off the live chains into data
            # (`out_of_region` / `runaway`) is NOT a chain — its "nodes" are whatever bytes lie there
            # and differ between the images by the relocation alone. The same holds for an index
            # entry whose walk ENDS cleanly in data (Phobos b:0x7f, c:0x48-0x8a: hbA 0x3a15, dur 57
            # native / 183 ours — relocated pointer bytes read as fields): a real node's SPRITE
            # pointer lies inside the tenant's own anim region (Pyron b:0x03 0x2735a6, b:0x19
            # 0x27ea80 in [0x264086,0x27f586)); one that points elsewhere is data, and such a
            # chain is counted on both sides, never compared
            off = 0 if side == "native" else dst - src
            def valid(c, off=off):
                if c.get("end") in ("out_of_region", "runaway"):
                    return False
                nodes = c.get("nodes") or []
                return bool(nodes) and all(src <= int(str(n.get("sprite", "0")), 16) - off < src + ln for n in nodes)
            out[side] = {seq: ([(n.get("dur"), n.get("flags"), n.get("sfx"), n.get("hbA")) for n in (c.get("nodes") or [])] if valid(c) else "INVALID")
                         for seq, c in ch.items()}
        n_ = out["native"]; o_ = out["ours"]
        inv_n = {k for k, v in n_.items() if v == "INVALID"}; inv_o = {k for k, v in o_.items() if v == "INVALID"}
        diff = sorted(set(k for k in set(n_) | set(o_) if n_.get(k) != o_.get(k) and not (k in inv_n and k in inv_o)), key=lambda x: int(x, 16))
        lines.append("table %s: %d chains native, %d ours, %d not chains on both (walks into data), %d differ in shape%s" % (
            name, len(n_), len(o_), len(inv_n & inv_o), len(diff), (": " + " ".join(diff)) if diff else ""))
        if inv_n & inv_o:
            lines.append("NOTCHAIN %s %s" % (name, " ".join(sorted(inv_n & inv_o, key=lambda x: int(x, 16)))))
        if diff or len(n_) != len(o_) or inv_n != inv_o:
            ok = False
            if inv_n != inv_o:
                lines.append("FAIL: table %s: the not-a-chain sets differ (native-only %s, ours-only %s)" % (
                    name, " ".join(sorted(inv_n - inv_o)) or "-", " ".join(sorted(inv_o - inv_n)) or "-"))
    return ok, lines


def chains_plant(extract_dir, ours_image, placements, tenant, out_image, table="b"):
    """a perturbed copy of OUR data view: the first VALID chain of `table` (as chains_identical
    classes it) gets its first node's dur byte +1 — the chains-planted control's input, so the
    identity check is shown able to report a shape difference (rule-checker run 2026-09-25-156 Q4)"""
    import subprocess, tempfile
    rj = json.load(open(os.path.join(extract_dir, "regions.json")))
    ptr = {v["table"]: int(v["ptr"], 16) for v in rj["values"] if v["table"].startswith("anim_index")}
    regs = json.load(open(placements))["regions"]
    key = "anim" if tenant == "donovan" else "anim@" + tenant
    dst, src, ln = regs[key]["dst"], regs[key]["src"], regs[key]["len"]
    tmp = tempfile.mkdtemp()
    img = bytearray(open(ours_image, "rb").read())
    sl = os.path.join(tmp, "ours_region.bin"); open(sl, "wb").write(bytes(img[dst:dst + ln]))
    j = os.path.join(tmp, "ours_%s.json" % table)
    subprocess.check_call(["python3", os.path.join(HERE, "anim_nodes.py"), sl, "--base", hex(dst), "--table", hex(ptr["anim_index_" + table] - src + dst),
                           "--name", table, "--end", hex(dst + ln), "--json", j], stdout=subprocess.DEVNULL)
    ch = json.load(open(j))["chains"]
    for seq in sorted(ch, key=lambda x: int(x, 16)):
        c = ch[seq]; nodes = c.get("nodes") or []
        if c.get("end") in ("out_of_region", "runaway") or not nodes:
            continue
        if not all(src <= int(str(n.get("sprite", "0")), 16) - (dst - src) < src + ln for n in nodes):
            continue
        addr = int(nodes[0]["addr"], 16)
        # the node's dur byte: located by reading the decoder's own value back from the image
        off = None
        for k in range(0x18):
            if img[addr + k] == nodes[0]["dur"] and nodes[0]["dur"]:
                off = k; break
        if off is None:
            continue
        img[addr + off] = (img[addr + off] + 1) & 0xFF
        open(out_image, "wb").write(bytes(img))
        print("planted: %s:%s first node %#x dur %d -> %d (byte +%#x)" % (table, seq, addr, nodes[0]["dur"], nodes[0]["dur"] + 1, off))
        return
    raise SystemExit("FAIL: no valid chain to plant into")


def main(argv):
    m = argv[0]
    if m == "translate":
        translate(argv[1], argv[2], argv[3], argv[4])
    elif m == "contacts":
        print("\n".join(reaction_map.contacts(argv[1], argv[2], argv[3], with_frame=True, max_labels=64)))
    elif m == "compare":
        events, spans = None, []
        if "--events" in argv:
            events = json.load(open(argv[argv.index("--events") + 1]))["events"]
        deltas = None
        if "--p1" in argv:
            i = argv.index("--p1")
            sn, so = p1diff_spans(argv[i + 1]), p1diff_spans(argv[i + 2])
            spans = sn + so; deltas = span_delta(sn, so)
        print("\n".join(compare(argv[1], argv[2], argv[3], argv[4], events, spans, deltas)))
    elif m == "p1check":
        first = 2300
        if "--from" in argv:
            first = int(argv[argv.index("--from") + 1])
        ok, lines = p1check(argv[1], argv[2], argv[3], int(argv[4], 16), first, argv[argv.index("--same") + 1])
        print("\n".join(lines))
        sys.exit(0 if ok else 1)
    elif m == "pinscheck":
        sys.exit(0 if pinscheck(argv[1], argv[2]) else 1)
    elif m == "poked":
        poked(argv[1], argv[2], argv[3])
    elif m == "plant-p1":
        plant_p1(argv[1], argv[2], argv[3], argv[4], argv[argv.index("--same") + 1])
    elif m == "chains-plant":
        chains_plant(argv[1], argv[2], argv[3], argv[4], argv[5])
    elif m == "chains-identical":
        ok, lines = chains_identical(argv[1], argv[2], argv[3], argv[4])
        print("\n".join(lines))
        sys.exit(0 if ok else 1)
    elif m == "swap-label":
        # perturbed copy: the FIRST line whose contact lies inside an attacker-differing span gets one label of its
        # path swapped (b:0x03 <-> b:0x19 or the first label's seq +1) — the tenant-planted control's input
        spans = p1diff_spans(argv[3]) + p1diff_spans(argv[4])
        events = json.load(open(argv[argv.index("--events") + 1]))["events"]
        ls = [l for l in open(argv[1]) if l.strip()]
        done = False
        with open(argv[2], "w") as fo:
            for l in ls:
                d = parse_line(l)
                # the same rule the attribution applies: the contact's EVENT holds a differing attacker span
                if not done and d["frame"] is not None and attacker_for(d["frame"], events, spans) != "-" and "--timing" in argv:
                    f = l.rstrip("\n").split("\t"); f[5] = "len=%d" % (int(d["len"][4:]) + 3); l = "\t".join(f) + "\n"
                    print("planted a tenant-side TIMING change (len +3) on: " + l.strip()[:120]); done = True
                elif not done and d["frame"] is not None and attacker_for(d["frame"], events, spans) != "-":
                    labs = d["path"].split(" ")
                    for i, lab in enumerate(labs):
                        if lab.startswith("b:0x03@"): labs[i] = lab.replace("b:0x03@", "b:0x19@"); break
                        if lab.startswith("b:0x19@"): labs[i] = lab.replace("b:0x19@", "b:0x03@"); break
                    else:
                        t, rest = labs[0].split(":0x", 1); seq, at = rest.split("@"); labs[0] = "%s:0x%02x@%s" % (t, int(seq, 16) + 1, at)
                    f = l.rstrip("\n").split("\t"); f[4] = " ".join(labs); l = "\t".join(f) + "\n"
                    print("planted a tenant-side label change on: " + l.strip()[:120]); done = True
                fo.write(l)
        if not done:
            raise SystemExit("FAIL: no line inside an attacker-differing span to plant into")
    elif m == "drop-first":
        ls = [l for l in open(argv[1]) if l.strip()]
        open(argv[2], "w").write("".join(ls[1:]))
        print("dropped: " + ls[0].rstrip("\n") if ls else "nothing to drop")
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
