#!/usr/bin/env python3
"""tables_char_md.py — render a ported character's extraction manifest and
behavioral values as the community-reviewable table (CLAUDE.md §2 rule 5).

  python3 tools/tables_char_md.py <extract_dir> <out.md> [--bank-map build/manifest/bank_map.toml]
  python3 tools/tables_char_md.py build/don_m19/extract docs/project/tables/donovan.md  # re-pointed 14z-130 (M13 boot-title freeze) <- 14z-119

READS  <extract_dir>/regions.json — what `tools/extract_char.py` wrote for the
       build (source set, oracle set, input SHA-1s, the measured shifts, every
       ported region with its SHA-1, the per-character VALUES, the gap tables
       the oracle classified).
       build/manifest/bank_map.toml — the vsavj row address and kind of every
       named per-character table (the single source of truth for addresses).
WRITES one markdown file. Deterministic: same inputs, same bytes, so the
       gate `tests/test_tables_current.sh` can diff a regeneration against the
       committed file and fail when the tables drift from the build.

WHY (14z-118, the documentation audit). `docs/project/tables/donovan.md` was
hand-written on 2026-08-09 from an early extract and never refreshed; by
14z-117 the shipped `param32_a` was a rec8 `00030000fffd6000` while the
table still said `FFFD0000`, and Huitzil/Pyron — promised by the README —
had no file at all. A hand-copied table is a claim with nothing behind it
the moment the build moves; a generated one is a MEASUREMENT of the build.
The maintainer ruled (2026-08-29): generate all three from the extractor.

Prints the SHA-1 of what it read (project convention).
"""
import argparse
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _minitoml import loads as toml_loads  # noqa: E402  (the project's own reader; no tomllib on 3.9)

REPO = Path(__file__).resolve().parent.parent
NAMES = {0x10: "Huitzil (Phobos)", 0x11: "Pyron", 0x13: "Donovan"}


def sha1_of(p):
    return hashlib.sha1(p.read_bytes()).hexdigest()


def load_bank_map(path):
    t = toml_loads(path.read_text())
    return {row["name"]: row for row in t.get("table", [])}


def fmt_val(v):
    """Group a hex string in 8-char words so a rec8 reads as two longs."""
    s = v.upper()
    if len(s) <= 8:
        return f"`{s}`"
    return "`" + " ".join(s[i:i + 8] for i in range(0, len(s), 8)) + "`"


def render(extract_dir, bank_map_path):
    rj = extract_dir / "regions.json"
    j = json.loads(rj.read_text())
    bm = load_bank_map(bank_map_path)
    cid = int(j["char"], 16) if isinstance(j["char"], str) else j["char"]
    name = NAMES.get(cid, f"id {cid:#04x}")
    out = []
    w = out.append
    w(f"# {name} (char id {cid:#04x}) — extraction manifest & behavioral values")
    w("")
    w("GENERATED — do not edit by hand. Regenerate with:")
    w("")
    w(f"    python3 tools/tables_char_md.py <build>/extract docs/project/tables/{Path(name.split()[0].lower()).name}.md")
    w("")
    w(f"Source set `{j['src_set']}`, oracle set `{j['oracle_set']}` "
      f"(`tools/extract_char.py`; every region is oracle-validated — see the "
      f"tool's header). Row addresses are vsavj, from `build/manifest/bank_map.toml`; "
      f"region addresses are {j['src_set']} (`src`) and {j['oracle_set']} (`orc`).")
    w("")
    w("## Inputs (SHA-1 of every member the extractor read)")
    w("")
    w("| member | SHA-1 |")
    w("|---|---|")
    for k, v in sorted(j["input_sha1s"].items()):
        w(f"| `{k}` | `{v}` |")
    w("")
    w("## Measured shifts (oracle − source, bytes)")
    w("")
    w("| region class | shift |")
    w("|---|---|")
    for k, v in j["shifts"].items():
        w(f"| `{k}` | `{v:+d}` (`{v & 0xFFFFFFFF:#010x}`) |")
    w("")
    w("## Region manifest")
    w("")
    w("| region | kind | src | orc | length | grow | refs | variant sites | char-id sites | SHA-1 |")
    w("|---|---|---|---|---|---|---|---|---|---|")
    for rname, r in j["regions"].items():
        w(f"| `{rname}` | {r.get('kind','')} | `PRG:{r['src']:#08x}` | `PRG:{r['orc']:#08x}` | "
          f"`{r['len']:#x}` | `{r.get('grow', 0):#x}` | {len(r.get('refs', []))} | "
          f"{len(r.get('variant_sites', []))} | {len(r.get('charid_sites', []))} | `{r.get('sha1','')}` |")
    w("")
    w("## Dispatch targets (the per-character code-pointer rows, source -> oracle)")
    w("")
    w("| table | src target | orc target |")
    w("|---|---|---|")
    for d in j.get("dispatch", []):
        w(f"| `{d['table']}` | `PRG:{d['src_target']:#08x}` | `PRG:{d['orc_target']:#08x}` |")
    w("")
    w("## VS2-vs-VH2 variant sites (maintainer-facing: where per-game flavour lives)")
    w("")
    w("Bytes that DIFFER between the source and oracle sets inside a ported region "
      "and are NOT explained by a pointer shift. The port ships the SOURCE value. "
      "A candidate 'VS2 vs VH2 flavour' tunable set — SPEC §3 variant policy.")
    w("")
    w("| region | offset in region | vsav2 byte | vhunt2 byte |")
    w("|---|---|---|---|")
    nvs = 0
    for rname, r in j["regions"].items():
        for vsite in r.get("variant_sites", []):
            nvs += 1
            w(f"| `{rname}` | `+{vsite['off']:#06x}` | `{vsite['src']:02X}` | `{vsite['orc']:02X}` |")
    if nvs == 0:
        w("| (none) | | | |")
    w("")
    w(f"## Per-character values (row {cid:#04x} of each 32-row table — the tunables)")
    w("")
    w("`value*`/`rec8`/`byte2d` rows are COPIED into the build (never repointed); "
      "`*_ptr` rows are the source-set pointers the port repoints to the relocated copy.")
    w("")
    w("| table | vsavj row base | kind | value / pointer |")
    w("|---|---|---|---|")
    for v in j["values"]:
        row = bm.get(v["table"], {})
        base = row.get("vsavj")
        base_s = f"`PRG:{base:#08x}`" if isinstance(base, int) else "(not in bank_map)"
        if "value" in v:
            val = fmt_val(v["value"])
        else:
            val = f"`{v['ptr']}`" + ("" if v.get("inside_region", True) else " (OUTSIDE its region)")
        w(f"| `{v['table']}` | {base_s} | {v['kind']} | {val} |")
    w("")
    w("## Gap tables classified by the oracle (`auto` kind — no documented consumer)")
    w("")
    w("| table | verdict | entry (first) |")
    w("|---|---|---|")
    for a in j["auto_tables"]:
        w(f"| `{a['table']}` | {a['verdict']} | `{a.get('entry_guess','')}` |")
    w("")
    w("Provenance of every byte above: `VS2` (source set) validated against `VH2` "
      "(oracle) — CLAUDE.md §2 rule 4. Consumers and semantics: "
      "`docs/game/atlas/character_tables.md`.")
    w("")
    return "\n".join(out), rj


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("extract_dir", type=Path)
    ap.add_argument("out", type=Path)
    ap.add_argument("--bank-map", type=Path, default=REPO / "build/manifest/bank_map.toml")
    a = ap.parse_args()
    text, rj = render(a.extract_dir, a.bank_map)
    a.out.write_text(text)
    print(f"read  {rj}  sha1 {sha1_of(rj)}")
    print(f"read  {a.bank_map}  sha1 {sha1_of(a.bank_map)}")
    print(f"wrote {a.out}  sha1 {hashlib.sha1(text.encode()).hexdigest()}  ({len(text.splitlines())} lines)")


if __name__ == "__main__":
    main()
