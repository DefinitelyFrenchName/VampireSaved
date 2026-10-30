#!/usr/bin/env python3
"""mizuumi_candidates.py — #118's per-candidate classification of the mizuumi community's player-struct candidates,
derived from docs/game/atlas/ram.md (14z-213; ruled 2026-10-30, DECISIONS_HISTORY.md "#118: drop t118-196; ... re-derive
the classification beside the atlas"). The table is docs/game/atlas/mizuumi_candidates.tsv; the gate
tests/test_mizuumi_candidates.sh.

  python3 tools/mizuumi_candidates.py check [--table T] [--ram R]   re-derive; exit 1 on any row that differs
  python3 tools/mizuumi_candidates.py write [--table T] [--ram R]   rewrite the derived columns

WHAT IS MAINTAINED, WHAT IS DERIVED
  offset and batch are the table's MAINTAINED columns: the scope (the 89 offsets of 14z-189's working list, seeded
  14z-213 from build/agent192/t118_record/classification.tsv) and the remaining measurement that would move a verdict
  (seeded from build/agent194/t118/HOMING.md's "Not measured" table by the BATCH RULES below; changed by hand when a
  batch is measured or re-planned). name, verdict and evidence are DERIVED from ram.md by the rules below, never
  hand-edited: `check` re-derives them and fails on any difference, so a ram.md change that moves a verdict shows here.

WHICH ram.md ROWS COUNT
  Every markdown table row of ram.md whose first cell (backticks stripped) starts
  with "+0x". The first cell is parsed into covered byte offsets:
    "+0xNNN.s"            NNN .. NNN+size-1   (.b 1, .w 2, .l 4; no suffix 1)
    "+0xA / +0xB (.w)"    each token, the parenthesised size applying to all
    "+0xA..+0xB", "+0xA..B"  the inclusive range
    "+0x80/84/88/8C/90.l" the slash shorthand: each value, the size applying to all
  A row's OWN offsets are its tokens' first bytes; a row COVERS every byte above.
  An offset is matched to its OWN rows if any, else to the rows that cover it.
  More than one candidate row -> the row(s) whose text quotes mizuumi; still more
  than one -> UNDECIDED (reason: several rows).

VERDICT RULES (applied to the matched row's whole text, first rule that fires wins;
case-sensitive where the word is upper-case in ram.md)
  R1 REFUTED IN PART  the text has "is REFUTED as" AND "is consistent"
                      (ram.md refutes part of the community text, keeps the rest).
  R2 REFUTED          the text has "the name REFUTED", or matches
                      "NOT a <...> as mizuumi names it".
  R3 NOT ADOPTED      the text has "NOT adopted" or "name is not adopted".
                      (ram.md: "RECORDED; mizuumi's "..." NOT adopted" — the behaviour
                      is measured and recorded, the community name is not established.)
  R4 NOT OBSERVED     the text has `mizuumi's "..." not observed` (the row's own
                      parenthesis says why: "(owner not observed)" or
                      "(owner writes zero only)").
  R5 OWNER ONLY       the text has `consistent with mizuumi's "..." as to OWNER only`
                      (the named character's own code writes the slot; the meaning
                      is not tested).
  R6 CROSS-CHECKED    the text has `mizuumi's "..." at +0xNN is this row's` with NN
                      the offset itself (a range row identifies the community name with
                      one of its own bytes).
  R7 CONSISTENT       the text has `consistent with mizuumi's` (any qualifier ram.md
                      appends, e.g. "(1P only)" or "but only ... is measured", is kept in
                      ram.md and listed by --compare, not encoded in the verdict).
  R8 COVERED          the row is a RANGE row (the offset is not one of its own) and
                      quotes no mizuumi name: ram.md documents the byte under its own
                      meaning; the community name is not compared.
  R9 NO ROW           no ram.md row owns or covers the offset.
  else UNDECIDED      a row exists and none of R1-R8 fires; the reason is emitted.

NAME
  The first `mizuumi's "..."` (or `Mizuumi's "..."`, `mizuumi's name "..."`) quote in
  the matched row, verbatim (ram.md's own
  quotation, so nothing longer than ram.md already carries); "-" when the row quotes
  none or there is no row.

EVIDENCE (";"-joined, in this order)
  row "<first cell>"                    the ram.md row the verdict rests on
  gate <tests/x.sh> [<check ids>]       every tests/*.sh the row cites, with the
                                        check ids written right after it (C13, A2/A2b ...)
  ungated per ram.md                    the row says "not yet gated" and cites no gate
                                        (a mention followed by "asserts no" is a negative
                                        mention and is not counted as a gate)
  PRG:0xNNNNNN,...                      every 6-hex-digit 0x literal in the row, in
                                        order of first appearance, upper-cased; a bare
                                        `0x0NNNNN` in ram.md is a program-ROM offset
                                        (ram.md writes RAM as $FFxxxx), so it is printed
                                        in [VSP-11] PRG: notation. Counts are NOT given:
                                        ram.md states them in prose, not per PC.
  For NO ROW: "no ram.md row" and the HOMING row it rests on.

BATCH RULES (the remaining measurement that would move the verdict)
  B-NOROW   NO ROW offsets: HOMING's "the state it needs" cell, first keyword that
            fires: "pixel/palette read" -> "static decode + palette read";
            "static" -> "static decode"; "finish" -> "finishes rig";
            "Anakaris" -> "Anakaris rig"; "Lilith" -> "Lilith rig";
            "charge" -> "charge-input rig"; none -> UNDECIDED (reason printed).
            An offset absent from HOMING's table -> UNDECIDED.
  B-OWNER   NOT OBSERVED rows: "<owner> rig", the owner being the character the row
            opens with ("Sasquatch played", "Felicia's code ..."): the named owner must
            perform the named move.
  else "-"  no source assigns a remaining measurement. NOT a claim that nothing is
            left to learn: --compare lists the "-" rows whose ram.md text records an
            unobserved condition.
  Rig batches are numbered B1.. by size (most offsets first, then name); "static
  decode" rows carry no number.

Prints the SHA-1 of every input it reads. Plain python, no numpy. Seeded from the 14z-213 draft
(build/agent213/t118/derive.py, local), whose --old/--homing inputs are untracked.
"""
import argparse
import hashlib
import re
import subprocess
import sys
from pathlib import Path

RAM_REL = "docs/game/atlas/ram.md"
SIZE = {"b": 1, "w": 2, "l": 4}


def sha1(b):
    return hashlib.sha1(b).hexdigest()


def git(repo, *args):
    return subprocess.run(["git", "-C", str(repo), *args], check=True,
                          capture_output=True).stdout


def split_cells(line):
    # a markdown row: split on | not escaped as \|
    body = line.strip()
    assert body.startswith("|")
    cells = re.split(r"(?<!\\)\|", body[1:])
    if cells and cells[-1].strip() == "":
        cells = cells[:-1]
    return [c.strip() for c in cells]


def parse_first_cell(cell):
    """-> (own offsets list, covered set) or None if the cell is not an offset cell."""
    c = cell.replace("`", "")
    c = re.sub(r"\(\$[^)]*\)", "", c)          # drop ($FF8782/$FF8B82) address notes
    if not c.startswith("+0x"):
        return None
    common = re.search(r"\(\.([bwl])\)", c)    # "(.w)" applying to every token
    common = SIZE[common.group(1)] if common else None
    own, cov = [], set()
    # ranges first: +0xA..+0xB / +0xA..B
    for m in re.finditer(r"\+0x([0-9A-Fa-f]+)\.\.\+?(?:0x)?([0-9A-Fa-f]+)", c):
        a, b = int(m.group(1), 16), int(m.group(2), 16)
        own.append(a)
        cov.update(range(a, b + 1))
    c2 = re.sub(r"\+0x[0-9A-Fa-f]+\.\.\+?(?:0x)?[0-9A-Fa-f]+", "", c)
    # slash shorthand +0x80/84/88/8C/90.l (bare hex after the slash, no "+0x")
    for m in re.finditer(r"\+0x([0-9A-Fa-f]+)((?:/[0-9A-Fa-f]+)+)\.([bwl])", c2):
        sz = SIZE[m.group(3)]
        vals = [m.group(1)] + m.group(2).strip("/").split("/")
        for v in vals:
            a = int(v, 16)
            own.append(a)
            cov.update(range(a, a + sz))
    c3 = re.sub(r"\+0x[0-9A-Fa-f]+(?:/[0-9A-Fa-f]+)+\.[bwl]", "", c2)
    for m in re.finditer(r"\+0x([0-9A-Fa-f]+)(?:\.([bwl]))?", c3):
        a = int(m.group(1), 16)
        sz = SIZE[m.group(2)] if m.group(2) else (common or 1)
        own.append(a)
        cov.update(range(a, a + sz))
    return own, cov


def read_rows(text):
    rows = []
    for n, line in enumerate(text.splitlines(), 1):
        if not line.startswith("| "):
            continue
        cells = split_cells(line)
        if not cells:
            continue
        p = parse_first_cell(cells[0])
        if p is None:
            continue
        rows.append(dict(line=n, first=cells[0].replace("`", "").strip(),
                         own=p[0], cov=p[1], text=line))
    return rows


MZ_QUOTE = re.compile(r"[Mm]izuumi's (?:name )?\"([^\"]+)\"")


def verdict(row, off):
    t = row["text"]
    if "is REFUTED as" in t and "is consistent" in t:
        return "REFUTED IN PART", "R1"
    if "the name REFUTED" in t or re.search(r"NOT a [^|]*? as mizuumi names it", t):
        return "REFUTED", "R2"
    if "NOT adopted" in t or "name is not adopted" in t:
        return "NOT ADOPTED", "R3"
    if re.search(r"mizuumi's \"[^\"]+\" not observed", t):
        return "NOT OBSERVED", "R4"
    if re.search(r"consistent with mizuumi's \"[^\"]+\" as to OWNER only", t):
        return "OWNER ONLY", "R5"
    m = re.search(r"mizuumi's \"[^\"]+\" at \+0x([0-9A-Fa-f]+) is this row's", t)
    if m and int(m.group(1), 16) == off:
        return "CROSS-CHECKED", "R6"
    if "consistent with mizuumi's" in t:
        return "CONSISTENT", "R7"
    if off not in row["own"] and not MZ_QUOTE.search(t):
        return "COVERED", "R8"
    return "UNDECIDED", "no rule R1-R8 fires on the row's text"


GATE_RE = re.compile(r"tests/([\w.-]+\.sh)`?((?:\s+(?:and\s+)?[A-Z]\d+[a-z]?(?:/[A-Z]\d+[a-z]?)*,?)*)")


def evidence(row):
    t = row["text"]
    ev = [f'row "{row["first"]}"']
    gates = []
    for m in GATE_RE.finditer(t):
        if t[m.end():m.end() + 12].lstrip().startswith("asserts no"):
            continue                      # "`tests/x.sh` asserts no +0xNNN check": a NEGATIVE mention
        ids = re.findall(r"[A-Z]\d+[a-z]?(?:/[A-Z]\d+[a-z]?)*", m.group(2))
        g = f"gate tests/{m.group(1)}" + (" " + " ".join(ids) if ids else "")
        # merge repeated mentions of one gate
        for i, old in enumerate(gates):
            if old.split(" ")[1] == f"tests/{m.group(1)}":
                more = [x for x in ids if x not in old.split(" ")[2:]]
                gates[i] = old + ("" if not more else " " + " ".join(more))
                break
        else:
            gates.append(g)
    ev += gates
    if not gates and "not yet gated" in t:
        ev.append("ungated per ram.md")
    pcs = []
    for m in re.finditer(r"0x([0-9A-Fa-f]{6})(?![0-9A-Fa-f])", t):
        p = "PRG:0x" + m.group(1).upper()
        if p not in pcs:
            pcs.append(p)
    if pcs:
        ev.append(",".join(pcs))
    return "; ".join(ev)


def read_homing(path):
    out = {}
    if not path or not Path(path).is_file():
        return out, None
    raw = Path(path).read_bytes()
    text = raw.decode("utf-8")
    sec = text.split("## Not measured", 1)
    if len(sec) < 2:
        return out, sha1(raw)
    body = sec[1].split("\n## ", 1)[0]
    for line in body.splitlines():
        if not line.startswith("| `+0x"):
            continue
        cells = split_cells(line)
        off = int(re.match(r"`\+0x([0-9A-Fa-f]+)`", cells[0]).group(1), 16)
        out[off] = cells[2]
    return out, sha1(raw)


def homing_batch(need):
    if "pixel/palette read" in need:
        return "static decode + palette read", "HOMING: " + "static + a pixel/palette read"
    for kw, label in (("static", "static decode"), ("finish", "finishes rig"),
                      ("Anakaris", "Anakaris rig"), ("Lilith", "Lilith rig"),
                      ("charge", "charge-input rig")):
        if kw in need:
            return label, None
    return "UNDECIDED", "HOMING's state names no move or state a rig could reach"


OWNER_RE = re.compile(r"^\|\s*[^|]+\|\s*([A-Z][\w-]*?)(?:'s (?:own )?code| played)")


def fmt(off):
    return f"+0x{off:X}"


def derive(rows, off):
    """-> (name, verdict, evidence, reason) for one offset over ram.md's rows (the rules above)"""
    mine = [r for r in rows if off in r["own"]]
    cand = mine or [r for r in rows if off in r["cov"]]
    if len(cand) > 1:
        q = [r for r in cand if MZ_QUOTE.search(r["text"])]
        cand = q if q else cand
    if not cand:
        return "-", "NO ROW", "no ram.md row", ""
    if len(cand) > 1:
        return "-", "UNDECIDED", "; ".join('row "%s"' % r["first"] for r in cand), "several ram.md rows own or cover the offset"
    r = cand[0]
    v, rule = verdict(r, off)
    m = MZ_QUOTE.search(r["text"])
    return (m.group(1) if m else "-"), v, evidence(r), (rule if v == "UNDECIDED" else "")


def read_table(path):
    head, rows = [], []
    for line in Path(path).read_text().splitlines():
        if line.startswith("#") or line.startswith("offset\t"):
            head.append(line); continue
        if line.strip():
            c = line.split("\t")
            rows.append(dict(offset=c[0], name=c[1], verdict=c[2], evidence=c[3], batch=c[4]))
    return head, rows


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("mode", choices=("check", "write"))
    root = Path(__file__).resolve().parents[1]
    ap.add_argument("--table", default=str(root / "docs/game/atlas/mizuumi_candidates.tsv"))
    ap.add_argument("--ram", default=str(root / RAM_REL))
    a = ap.parse_args()
    ram_raw = Path(a.ram).read_bytes()
    print("read %s  sha1 %s" % (a.ram, sha1(ram_raw)))
    rows = read_rows(ram_raw.decode("utf-8"))
    head, tab = read_table(a.table)
    offs = [t["offset"] for t in tab]
    if len(set(offs)) != len(offs):
        sys.exit("FAIL: duplicate offset in %s" % a.table)
    bad = 0
    for t in tab:
        name, v, ev, why = derive(rows, int(t["offset"][3:], 16))
        if (name, v, ev) != (t["name"], t["verdict"], t["evidence"]):
            bad += 1
            if a.mode == "check":
                print("DIFFERS\t%s\ttable: %s | %s\tram.md: %s | %s" % (t["offset"], t["verdict"], t["name"], v, name))
            t.update(name=name, verdict=v, evidence=ev)
        if why:
            print("UNDECIDED\t%s\t%s" % (t["offset"], why))
    cnt = {}
    for t in tab:
        cnt[t["verdict"]] = cnt.get(t["verdict"], 0) + 1
    summary = ", ".join("%s %d" % kv for kv in sorted(cnt.items(), key=lambda x: (-x[1], x[0])))
    if a.mode == "write":
        Path(a.table).write_text("\n".join(head + ["\t".join([t["offset"], t["name"], t["verdict"], t["evidence"], t["batch"]]) for t in tab]) + "\n")
        print("wrote %s: %d rows (%d changed); %s" % (a.table, len(tab), bad, summary))
        return 0
    print("%s: %d offsets, %d differ from ram.md; %s" % ("PASS" if not bad else "FAIL", len(tab), bad, summary))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
