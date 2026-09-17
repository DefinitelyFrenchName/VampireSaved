#!/usr/bin/env python3
"""audit_poked_legs.py — THE CENSUS OF EVERY FORCED-PICK LEG, and what each one
carries wrong (GitHub #151 step 3, 14z-161).

A forced pick pokes RAM:$FF8782 (P1) / RAM:$FF8B82 (P2) at frames 1400-1500
([VSP-123]), AFTER the select confirm (~1299) has written per-fighter state for
the cell the cursor is ON. `tests/audit_forced_pick_fidelity.sh` measured what
that leaves: the id copies `+0x3BD`/`+0x3E0` and the VS2/VH2 flavor `+0x3C2`.
Whether a poked leg's SUBJECT can depend on it is decided by two facts, both
measured 14z-161 rather than assumed:

  1. WHAT THE CONFIRM WRITES INTO THE FLAVOR, per cell (vs2 opcode view,
     PRG:0x01F832 / PRG:0x01F86A): Phobos's cell 0x10 writes 00 (01 with Start
     held), Donovan's cell 0x13 writes 01 (00 with Start held), and NO OTHER CELL
     writes it — the select-entry clear (PRG:0x01F5C8) leaves 00. So the flavor
     a poked fighter reads is wrong in exactly two shapes: Phobos (0x10) poked
     over Donovan's cell, or Donovan (0x13) poked over any other cell.
  2. WHO READS THE LATCH IN PLAY (tools/tap_latch_reads.sh over 23 legs, both
     games): only Phobos's code reads the flavor (vs2 PRG:0x026322 every match
     frame, 0x02595A/0x02598A in jumps; ours 0x41D2C0/0x41D2F0), and NO leg read
     an id copy after the match anchor — their static readers (tools/
     audit_latch_readers.py) sit under the Shadow flag `+0x3BC`, in the arcade
     ladder and in the HUD-name stager ([VSP-121]). Donovan's flavor readers did
     not fire on any of his tapped legs (eight victim parts, the immortal rig).

The census therefore classifies every poked SIDE of every leg as:
  SAME          the poke writes the id the cursor cell already holds — inert
                (the donovan-self row of the fidelity gate);
  CROSS-INERT   a different id, but the flavor the fighter would read is the
                same as a real pick's and the id copies are unread in play;
  CROSS-FLAVOR  shape 1 above — the fighter reads a flavor a real pick would not
                write; the leg is UNFAITHFUL unless a tap shows no read;
  PARAM         the id is a shell variable this census could not expand — the
                cells it would be CROSS-FLAVOR for are named instead.

A ROW IS A SCRIPT-LEVEL PAIRING, not an executed leg: the census pairs every
replay a script names with every poke it names, per game the script boots, so
a script whose native leg runs replay 97 alone still gets a row for replay 98.
That over-approximation is deliberate (a static census cannot follow the shell)
and is why the accepted list carries a reason per row; the dynamic half,
tests/audit_latch_reads.sh, is what turns a class into a measured verdict.

The wheel is the leg's game's: vsav2's TABLE B for a native leg, the WIDE
build's for an ours leg (solo and merged wheels are identical, measured).
P1 starts on cell 0x01, P2 on 0x05 (tools/select_paths.py --check); cell IS id.

Usage:
  audit_poked_legs.py --vsav2 wheel_vsav2.json --wide wheel_merged.json [--tsv out] [--repo .]
  exit 1 if any CROSS-FLAVOR leg is not listed in --accepted (a TSV of known ones)
"""
import argparse, json, os, re, sys
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from select_paths import resolve, START  # noqa: E402

NAMES = {0x00: "Bulleta", 0x01: "Demitri", 0x02: "Gallon", 0x03: "Victor", 0x04: "Zabel", 0x05: "Morrigan",
         0x06: "Anakaris", 0x07: "Felicia", 0x08: "Bishamon", 0x09: "Aulbath", 0x0A: "Q-Bee", 0x0B: "random",
         0x0C: "Lei-Lei", 0x0D: "Lilith", 0x0E: "Sasquatch", 0x0F: "Jedah", 0x10: "Phobos", 0x11: "Pyron",
         0x12: "Marionette", 0x13: "Donovan", 0x18: "Oboro"}
FLAVOR_CELLS = {0x10: 0x00, 0x13: 0x01}          # what the confirm writes on that cell; others leave 00
POKE_RE = re.compile(r"(\d+):(ff8782|ff8b82):(\$\{?\w+\}?|[0-9a-fA-F]{2})")
RPL_RE = re.compile(r"replays/[\w./-]+\.rpl")
LINE_RE = re.compile(r"^(\d+)(?:-(\d+))?\s+(.*)$")


def flavor_on(cell):
    return FLAVOR_CELLS.get(cell, 0x00)


def classify(cell, pid, leg="native"):
    """An OURS leg is never CROSS-FLAVOR: vsavj's confirm does not write +0x3C2
    (tools/audit_latch_readers.py on the vsavj view finds no writer) and the
    port's init shim writes the tenant's flavor at char init, after any poke
    (character_tables.md "Start-hold flavor")."""
    if cell is None:
        return "?"
    if pid == cell:
        return "SAME"
    if leg == "native" and flavor_on(cell) != flavor_on(pid) and pid in FLAVOR_CELLS:
        return "CROSS-FLAVOR"
    return "CROSS-INERT"


def prologue_cells(rpl_path, tb):
    """(P1 cell, P2 cell) confirmed by the replay's cursor moves before each
    side's first button press; None where the side never confirms."""
    moves = {1: [], 2: []}
    confirm = {1: None, 2: None}
    for raw in open(rpl_path):
        line = raw.split("#", 1)[0].strip()
        m = LINE_RE.match(line)
        if not m:
            continue
        a = int(m.group(1)); rest = m.group(3)
        if rest == "wait" or a > 2000:
            continue
        for item in rest.split():
            who, _, toks = item.partition("=")
            if who not in ("p1", "p2"):
                continue
            pl = int(who[1])
            if confirm[pl] is not None:
                continue
            if toks.isdigit():
                confirm[pl] = a
            elif toks in ("R", "L", "D", "U", "DR", "DL", "UR", "UL"):
                moves[pl].append(toks)
    out = {}
    for pl in (1, 2):
        out[pl] = resolve(tb, START[pl], moves[pl]) if confirm[pl] is not None else None
    return out[1], out[2], moves


def expand_var(text, var):
    """Best effort: the hex ids a shell variable ranges over in this script."""
    v = var.strip("${}")
    ids = set()
    for m in re.finditer(r"for\s+" + re.escape(v) + r"\s+in\s+([^;\n]+)", text):
        for tok in m.group(1).split():
            tok = tok.strip('"\'')
            if re.fullmatch(r"[0-9a-fA-F]{2}", tok):
                ids.add(int(tok, 16))
            elif tok.startswith("$"):
                ids |= expand_var(text, tok)
    for m in re.finditer(r"(?m)^\s*" + re.escape(v) + r"=[\"']?([0-9a-fA-F ]+)[\"']?\s*(#.*)?$", text):
        for tok in m.group(1).split():
            if re.fullmatch(r"[0-9a-fA-F]{2}", tok):
                ids.add(int(tok, 16))
    return ids


def scan_script(path, wheels):
    text = open(path, errors="replace").read()
    native = bool(re.search(r"\bvsav2\b", text)) and bool(re.search(r"run_mame\.sh|run_replay_mame\.sh|run_replay_guarded\.sh|MAME_ROMPATH|-autoboot_script", text))
    ours = bool(re.search(r"vsavjw|rompath|%MERGED%|BUILD", text))
    pokes = {}
    for m in POKE_RE.finditer(text):
        side = 1 if m.group(2) == "ff8782" else 2
        pokes.setdefault(side, set()).add(m.group(3))
    if not pokes:
        return []
    rpls = sorted(set(RPL_RE.findall(text)))
    rows = []
    legs = [("native", "vsav2")] if native else []
    if ours:
        legs.append(("ours", "wide"))
    for leg, wheel in legs:
        tb = wheels[wheel]
        for rpl in rpls or ["(replay not named in the script)"]:
            rp = os.path.join(os.path.dirname(path), "..", "tests", rpl) if False else os.path.join(REPO, "tests", rpl)
            if rpl.startswith("(") or not os.path.exists(rp):
                cells = (None, None, {1: [], 2: []})
            else:
                cells = prologue_cells(rp, tb)
            for side in (1, 2):
                for pid in sorted(pokes.get(side, ())):
                    cell = cells[side - 1]
                    route = " ".join(cells[2][side]) or "-"
                    if re.fullmatch(r"[0-9a-fA-F]{2}", pid):
                        ids = [int(pid, 16)]; param = ""
                    else:
                        ids = sorted(expand_var(text, pid)); param = pid
                    if not ids:
                        risk = [f"{i:#04x}" for i in FLAVOR_CELLS if leg == "native" and cell is not None and flavor_on(cell) != flavor_on(i)]
                        rows.append((os.path.relpath(path, REPO), leg, rpl, f"P{side}", route, cell, param, "PARAM",
                                     "CROSS-FLAVOR if id in " + ",".join(risk) if risk else "no id is CROSS-FLAVOR here"))
                        continue
                    for i in ids:
                        rows.append((os.path.relpath(path, REPO), leg, rpl, f"P{side}", route, cell, f"{i:02x}" + (f" ({param})" if param else ""),
                                     classify(cell, i, leg), ""))
    return rows


def main():
    global REPO
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--vsav2", required=True, help="tools/select_wheel.py --json of vsav2")
    ap.add_argument("--wide", required=True, help="the same for a WIDE build (verify_data.bin, --set vsavj)")
    ap.add_argument("--repo", default=os.path.join(HERE, ".."))
    ap.add_argument("--tsv")
    ap.add_argument("--accepted", help="a frozen TSV of the CROSS-FLAVOR legs already known; any other is a new finding (exit 1)")
    ap.add_argument("--extra-script", action="append", default=[], help="scan this script too (the census gate's control feeds a fixture here)")
    a = ap.parse_args()
    REPO = os.path.abspath(a.repo)
    wheels = {"vsav2": json.load(open(a.vsav2))["table_b"], "wide": json.load(open(a.wide))["table_b"]}
    paths = sorted(os.path.join(REPO, "tests", f) for f in os.listdir(os.path.join(REPO, "tests")) if f.endswith(".sh"))
    paths += sorted(os.path.join(REPO, "tools", f) for f in os.listdir(os.path.join(REPO, "tools")) if f.endswith(".sh"))
    rows = []
    for p in paths + [os.path.abspath(x) for x in a.extra_script]:
        rows += scan_script(p, wheels)
    # name_moves.py's generated rigs: TENANTS with an id and no path are poked
    nm = os.path.join(REPO, "tools", "name_moves.py")
    if os.path.exists(nm):
        ns = {}
        src = open(nm).read()
        m = re.search(r"TENANTS = (\{.*?\}\})\n", src, re.S)
        if m:
            try:
                ten = eval(m.group(1), {"__builtins__": {}}, {})
                for name, t in ten.items():
                    if t.get("id") and not t.get("path"):
                        rows.append(("tools/name_moves.py", "native", f"replays/naming/{name}_*.rpl", "P1", "R R", 0x13 if True else None,
                                     t["id"], classify(0x13, int(t["id"], 16)), "the rig's prologue is replay 17's (P1 R,R on vsav2)"))
                    if t.get("id_p2"):
                        rows.append(("tools/name_moves.py", "native", f"replays/naming/{name}_*.rpl", "P2", "R R", 0x03,
                                     t["id_p2"], classify(0x03, int(t["id_p2"], 16)), "P2 R,R is Victor on vsav2"))
            except Exception as e:  # noqa: BLE001
                rows.append(("tools/name_moves.py", "?", "?", "?", "?", None, "?", "?", f"TENANTS not parsed: {e}"))
    rows.sort()
    hdr = ["script", "leg", "replay", "side", "route", "cell", "poke", "class", "note"]
    def fmt(r):
        cell = "-" if r[5] is None else f"{r[5]:02x} {NAMES.get(r[5], '?')}"
        return "\t".join([r[0], r[1], r[2], r[3], r[4], cell, str(r[6]), r[7], r[8]])
    lines = [fmt(r) for r in rows]
    if a.tsv:
        with open(a.tsv, "w") as f:
            f.write("# audit_poked_legs.py — every forced-pick leg in tests/ and tools/, classified (see the tool's docstring)\n")
            f.write("\t".join(hdr) + "\n" + "\n".join(lines) + "\n")
    counts = {}
    for r in rows:
        counts[r[7]] = counts.get(r[7], 0) + 1
    scripts = sorted({r[0] for r in rows})
    print(f"{len(rows)} poked sides across {len(scripts)} scripts: " + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())))
    flav = [r for r in rows if r[7] == "CROSS-FLAVOR"]
    for r in flav:
        print("  CROSS-FLAVOR  " + fmt(r))
    for r in rows:
        if r[7] == "PARAM":
            print("  PARAM         " + fmt(r))
    if a.accepted:
        known = set()
        for line in open(a.accepted):
            if line.startswith("#") or not line.strip():
                continue
            p = line.rstrip("\n").split("\t")
            if len(p) < 5:
                continue
            known.add((p[0], p[1], p[2], p[3], p[4]))          # script, leg, replay, side, poke (bare hex)
        key = lambda r: (r[0], r[1], r[2], r[3], str(r[6]).split()[0])
        new = [r for r in flav if key(r) not in known]
        gone = known - {key(r) for r in flav}
        for r in new:
            print("NEW CROSS-FLAVOR leg (not in the accepted list): " + fmt(r))
        for k in sorted(gone):
            print("accepted CROSS-FLAVOR leg no longer poked (shrink — update the list): " + "\t".join(k))
        if new:
            sys.exit(1)


if __name__ == "__main__":
    main()
