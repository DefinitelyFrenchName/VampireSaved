#!/usr/bin/env python3
"""xlsx_read.py — a minimal, dependency-free .xlsx reader (stdlib zipfile +
ElementTree). Written for the community frame-data cross-check (14z-125), whose
source workbook lives OUTSIDE the tree and must be readable by any checkout
without pip installing anything.

  from xlsx_read import Workbook
  wb = Workbook(path)
  wb.sheet_names            -> ['FE', 'AN', ...] in workbook order
  wb.rows('DE')             -> [{'move': ..., 'input': ...}, ...] keyed by HEADER NAME

THE TRAPS IT EXISTS TO AVOID, every one of them measured in this workbook:
  * ROWS OMIT EMPTY CELLS. A naive positional read of `<c>` elements shifts
    every value after the first gap — that is how a first pass had Demitri's
    2HK reporting `gauge hit = 'crouching normal'` (the `type` column). Cells
    are placed by their `r` COLUMN LETTER, never by their order.
  * COLUMNS ARE NOT POSITIONAL ACROSS SHEETS. `AN` has a different 20-column
    schema (no throw-tech columns, plus `curse time`), so column J is
    `red damage` there and `throw tech` everywhere else. Rows are keyed by
    header NAME.
  * FORMULAS. 27 cells are formulas (all of `AN`'s `input` column among them).
    The cached <v> is what we want, and that is what this returns — the
    equivalent of openpyxl's data_only=True.
  * INLINE STRINGS (`t="inlineStr"`) as well as the shared-string table.
  * A sheet may declare a huge dimension (`SA` says 1003 rows) with only ~53
    populated; blank rows are dropped.
"""
import re
import zipfile
import xml.etree.ElementTree as ET

NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
RNS = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"


def col_index(ref):
    """'C7' -> 2 (0-based column)."""
    letters = re.match(r"([A-Z]+)", ref).group(1)
    n = 0
    for ch in letters:
        n = n * 26 + (ord(ch) - 64)
    return n - 1


class Workbook:
    def __init__(self, path):
        self.z = zipfile.ZipFile(path)
        self.shared = []
        if "xl/sharedStrings.xml" in self.z.namelist():
            for si in ET.fromstring(self.z.read("xl/sharedStrings.xml")):
                self.shared.append("".join(t.text or "" for t in si.iter() if t.tag == NS + "t"))
        rels = {r.get("Id"): r.get("Target")
                for r in ET.fromstring(self.z.read("xl/_rels/workbook.xml.rels"))}
        wb = ET.fromstring(self.z.read("xl/workbook.xml"))
        self._sheets = []
        for s in wb.iter(NS + "sheet"):
            tgt = rels[s.get(RNS + "id")]
            self._sheets.append((s.get("name"), tgt if tgt.startswith("xl/") else "xl/" + tgt.lstrip("/")))

    @property
    def sheet_names(self):
        return [n for n, _ in self._sheets]

    def _cell(self, c):
        t = c.get("t")
        if t == "inlineStr":
            el = c.find(NS + "is")
            return "".join(x.text or "" for x in el.iter() if x.tag == NS + "t") if el is not None else ""
        v = c.find(NS + "v")          # the CACHED value, formula or not
        if v is None or v.text is None:
            return ""
        return self.shared[int(v.text)] if t == "s" else v.text

    def grid(self, name):
        """[[cell, ...], ...] with blanks materialised, blank rows dropped."""
        tgt = dict(self._sheets)[name]
        out = []
        for row in ET.fromstring(self.z.read(tgt)).iter(NS + "row"):
            cells = {}
            for c in row.iter(NS + "c"):
                ref = c.get("r")
                if ref:
                    cells[col_index(ref)] = self._cell(c)
            if not cells or not any(str(v).strip() for v in cells.values()):
                continue
            out.append([cells.get(i, "") for i in range(max(cells) + 1)])
        return out

    def rows(self, name):
        """Header row 1; each later row as {header: value}, blanks kept as ''."""
        g = self.grid(name)
        if not g:
            return []
        hdr = [str(h).strip() for h in g[0]]
        out = []
        for r in g[1:]:
            out.append({hdr[i]: r[i] for i in range(min(len(hdr), len(r))) if hdr[i]})
        return out
