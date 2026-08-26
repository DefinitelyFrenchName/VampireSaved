#!/usr/bin/env python3
"""audit_fsm_census.py — the STATIC object-script node-state census (14z-110,
GitHub #99): every ported node-state byte >= vsavj's FSM table size, walked the
way the dispatcher walks — by NODE, never by a blanket byte scan.

WHY. #99 is a vs2-numbered node-state byte (0x51) in Donovan's ported block
over-indexing vsavj's 80-entry object-script state table -> vec3 -> soft
reboot. The engines RENUMBERED the family: vs2's tables have 84 entries
(0x00-0x53), vsavj's have 80 (0x00-0x4F). A ported record carries vs2's index
verbatim, so any node whose +0x17 state byte is in [0x50,0x53] is valid in vs2
and OUT OF RANGE in vsavj. This audit enumerates every such node in every
tenant, so a missed family member is caught at BUILD time instead of on a CRT
(the standing rule, docs/project/gotchas.md "Every TYPE/CLASS byte...").

THE DISPATCHER (docs/game/engine_internals.md "The object-script state
dispatcher at PRG:0x018508"). Three sibling dispatchers (0x018460 / 0x018508 /
0x0185D2) read the node's +0x17 byte, double it, and index an 80-entry
PC-relative word table with NO bounds check. vs2's twins (0x016D2C / 0x016DDC /
0x016EAE, tables 0x016D34 / 0x016DE4 / 0x016EB6) have 84 entries. Valid vsavj
range: 0x00-0x4F. The renumber gap: 0x50-0x53.

HOW WE FIND NODES, NOT COINCIDENCES. A ported block is not uniformly node
records — a blanket scan for bytes 0x50-0x53 at the +0x17 position yields
HUNDREDS of coincidences in coordinate tables, palette data and code (measured
14z-110). The node-record SIGNATURE discriminates: object-script state nodes
are a CONTIGUOUS run of 0x20-byte records carrying a MONOTONIC frame counter at
+0x10 and a valid-state byte (<=0x53) at +0x17. That structural signature
uniquely isolates the real state-node arrays. Confirmed against the dynamic
oracle: tests/lua/fsm_census.lua watched the live dispatcher read node
A3=0x3FB882 (the #99 crash node, in this exact array) and A3=0x3FB4A2 (same
0x20 grid, phase 2, valid index) — so the arrays this signature reports are the
arrays the engine actually walks.

BOUND (RH-19/60). The signature encodes THIS node family's structure. A
state-node array with a different record layout carrying 0x50-0x53 would not be
reported here; the dynamic census (fsm_census.lua over the corpus) is the
reachability complement, and it found no >=0x50 dispatch in a full match. State
this bound; do not read a clean census as a proof of universal absence.

CLASSIFICATION per hit (the maintainer's ruling, 2026-08-26): DEFAULT-ALIAS if
vs2's handler for the index is byte-identical to vsavj's copy/default handler
0x01868C (a data remap or an equivalent code route is instruction-exact);
otherwise ESCALATE (its own maintainer decision). NOTE the copy handler
0x01868C == vs2's 0x016F70 == reaction_hook case_a2, byte-for-byte.

Usage:
    tools/audit_fsm_census.py <build_dir> [--check <inventory.toml>]
                              [--freeze <inventory.toml>] [--json]
Reads <build>/verify_data.bin (the DATA view; node bytes are data-space) and
<build>/verify_op.bin (the OPCODE view; the dispatcher tables are pc-relative).
No emulator, no ROMs, seconds. --check exits non-zero on any drift from the
frozen inventory (the build-time guard). --freeze writes the inventory.
"""
import argparse, re, struct, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cps2_decrypt as cps  # noqa: E402

VSAVJ_ENTRIES = 80          # 0x00-0x4F valid; 0x50+ out of range
VS2_ENTRIES = 84            # 0x00-0x53 valid in vs2 -> the renumber gap is 0x50-0x53
STRIDE = 0x20
CNT_OFF = 0x10
IDX_OFF = 0x17
COPY_HANDLER = 0x01868C     # vsavj default/copy handler (== vs2 0x016F70)
# the three sibling dispatchers and their vs2 twins (dispatcher, table, vs2 table)
DISPATCHERS = [
    ("d1_018460", 0x018468, 0x016D34),
    ("d2_018508", 0x018510, 0x016DE4),
    ("d3_0185D2", 0x0185DA, 0x016EB6),
]


def node_runs(blob, base):
    """Yield (start_index_in_blob, [state_bytes]) for every contiguous run of
    >=4 records whose +0x10 is a monotonic (+1) counter and whose +0x17 is a
    valid state (<=0x53) — the object-script node-array signature."""
    for phase in range(STRIDE):
        recs = []
        i = phase
        while i + IDX_OFF < len(blob):
            recs.append((i, blob[i + CNT_OFF], blob[i + IDX_OFF]))
            i += STRIDE
        j = 0
        while j < len(recs):
            k = j
            while (k + 1 < len(recs) and recs[k][2] <= 0x53 and recs[k + 1][2] <= 0x53
                   and recs[k + 1][1] == (recs[k][1] + 1) & 0xFF):
                k += 1
            if recs[j][2] <= 0x53 and k - j + 1 >= 4:
                seg = recs[j:k + 1]
                yield base + seg[0][0], [(base + r[0], r[2]) for r in seg]
            j = k + 1 if k > j else j + 1


def _tgt(img, table, idx):
    off = struct.unpack(">h", img[table + 2 * idx:table + 2 * idx + 2])[0]
    return table + off


def classify(vsavj_op, vs2_op, idx):
    """Dispatcher-level equivalence of node-state `idx` between vs2 (where it is
    valid) and vsavj (where it over-indexes). For each of the three sibling
    dispatchers, compare vs2's twin-table handler bytes against vsavj's copy
    handler 0x01868C. DEFAULT-ALIAS iff all three vs2 handlers ARE the copy
    handler AND some vsavj index also routes there (a data remap or a code
    route is then instruction-exact). Otherwise ESCALATE, naming the divergent
    dispatchers.

    NOTE (measured 14z-110): dispatcher-level equivalence is necessary, NOT
    sufficient. When idx becomes the STORED class (the copy handler writes
    (0x17,a3) into (0x54,a1)), a downstream property lookup keys on that class
    — so a data remap that satisfies every dispatcher can still change
    property[class] (the 14z-43/44 ES-freeze family: property[0x51]=0x19). That
    dependency is why even a dispatcher-exact remap of the 0x51 family is a
    maintainer decision. Reported as `prop_dependent`."""
    if vs2_op is None:
        return "UNCLASSIFIED", [], False
    copy = vsavj_op[COPY_HANDLER:COPY_HANDLER + 8]
    diverge = []
    for name, _tab, vs2_tab in DISPATCHERS:
        tgt = _tgt(vs2_op, vs2_tab, idx)
        if vs2_op[tgt:tgt + 8] != copy:
            diverge.append((name, tgt))
    # does the copy handler store the class (creating a property dependency)?
    prop_dep = copy[:2] == b"\x13\x6b"   # move.b (0x17,a3),(0x54,a1)
    if not diverge:
        return "DEFAULT-ALIAS", [], prop_dep
    return "ESCALATE", diverge, prop_dep


def load_vs2_op(vs2_zip):
    if not vs2_zip:
        return None
    words, keybytes, prgs, sha1s = cps.load_set(vs2_zip)
    cipher = cps.Cipher(keybytes)
    print(f"  vs2 oracle: {Path(vs2_zip).name}  sha1 {sha1s[prgs[0]]}", file=sys.stderr)
    w = cipher.crypt_words_at(words, 0, decrypt=True)
    return bytes(cps.words_to_logical_bytes(w))


def load_regions(build):
    frag = (build / "patch" / "atlas_fragment.md").read_text()
    out = []
    for m in re.finditer(r'\| `PRG:0x([0-9A-Fa-f]+)` \| 0x([0-9A-Fa-f]+) \| VS2 \| (.+?) \|', frag):
        out.append((int(m.group(1), 16), int(m.group(2), 16), m.group(3).strip()))
    return out


def census(build, vs2_op=None):
    data = (build / "verify_data.bin").read_bytes()
    op = (build / "verify_op.bin").read_bytes()
    regions = load_regions(build)
    hits = []
    for dst, ln, what in regions:
        blob = data[dst:dst + ln]
        seen_bases = set()
        for run_start, states in node_runs(blob, dst):
            for addr, sb in states:
                if sb >= VSAVJ_ENTRIES and addr not in seen_bases:
                    seen_bases.add(addr)
                    cls, div, prop = classify(op, vs2_op, sb)
                    hits.append({
                        "node": addr, "idx": sb, "region": what,
                        "class": cls, "prop_dependent": prop,
                        "diverge": [f"{n}@{t:#x}" for n, t in div],
                    })
    hits.sort(key=lambda h: h["node"])
    return hits


def fmt_inventory(hits):
    lines = ["# fsm_census — frozen inventory of ported node-state bytes >= 0x50",
             "# (14z-110, GitHub #99). Regenerate: tools/audit_fsm_census.py <build> --freeze <this>",
             ""]
    for h in hits:
        lines.append(f'[[node]]')
        lines.append(f'addr = 0x{h["node"]:06X}')
        lines.append(f'idx = 0x{h["idx"]:02X}')
        lines.append(f'klass = "{h["class"]}"')
        lines.append(f'region = "{h["region"]}"')
        lines.append("")
    return "\n".join(lines) + "\n"


def parse_inventory(text):
    inv = []
    cur = None
    for ln in text.splitlines():
        ln = ln.strip()
        if ln == "[[node]]":
            cur = {}; inv.append(cur)
        elif cur is not None and "=" in ln and not ln.startswith("#"):
            k, v = [x.strip() for x in ln.split("=", 1)]
            if k == "addr": cur["node"] = int(v, 16)
            elif k == "idx": cur["idx"] = int(v, 16)
            elif k == "klass": cur["class"] = v.strip('"')
    return inv


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("build")
    ap.add_argument("--vs2", help="vsav2.zip — the classification oracle (else UNCLASSIFIED)")
    ap.add_argument("--check")
    ap.add_argument("--freeze")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()
    build = Path(a.build)
    for f in ("verify_data.bin", "verify_op.bin"):
        if not (build / f).exists():
            print(f"SKIP: no {f} in {build}")
            return 0
    vs2_op = load_vs2_op(a.vs2) if a.vs2 else None
    hits = census(build, vs2_op)

    if a.json:
        import json
        print(json.dumps(hits, indent=2)); return 0

    print(f"FSM node-state census of {build} — vsavj table {VSAVJ_ENTRIES} entries "
          f"(valid 0x00-0x{VSAVJ_ENTRIES-1:02X}); vs2 {VS2_ENTRIES} (gap 0x50-0x53)")
    print(f"node-record signature: {STRIDE:#x}-stride, monotonic +{CNT_OFF:#x} counter, "
          f"+{IDX_OFF:#x} state <= 0x53, run >= 4")
    esc = 0
    for h in hits:
        tag = h["class"]
        if h["class"] == "ESCALATE":
            esc += 1
            tag += " diverge=" + ",".join(h["diverge"])
        if h.get("prop_dependent"):
            tag += " prop_dependent"
        print(f"  node {h['node']:#08x} +0x17=0x{h['idx']:02X} [{h['region'][:34]}] {tag}")
    print(f"total out-of-range node-state bytes: {len(hits)}  (escalate: {esc})")
    print("BOUND: signature-based; a differently-structured node array carrying "
          "0x50-0x53 is not covered — dynamic census (fsm_census.lua) is the complement.")

    if a.freeze:
        Path(a.freeze).write_text(fmt_inventory(hits))
        print(f"froze {len(hits)} nodes to {a.freeze}")
        return 0

    if a.check:
        want = parse_inventory(Path(a.check).read_text())
        got = [{"node": h["node"], "idx": h["idx"], "class": h["class"]} for h in hits]
        wkey = sorted((w["node"], w["idx"], w["class"]) for w in want)
        gkey = sorted((g["node"], g["idx"], g["class"]) for g in got)
        if wkey != gkey:
            print("FAIL: census differs from frozen inventory")
            ws, gs = set(wkey), set(gkey)
            for x in sorted(gs - ws): print(f"  ADDED   node {x[0]:#08x} idx 0x{x[1]:02X} {x[2]}")
            for x in sorted(ws - gs): print(f"  MISSING node {x[0]:#08x} idx 0x{x[1]:02X} {x[2]}")
            return 1
        print(f"OK: census matches frozen inventory ({len(hits)} nodes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
