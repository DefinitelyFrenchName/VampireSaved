#!/usr/bin/env python3
"""reconcile_batch.py — batch-resolve the R1 engine references: for every
engine-class target in the extraction manifest, find the vsavj equivalent
by wildcarded instruction-pattern search (code targets) or exact-byte
search (data targets), and emit reconciliation.toml rows.

Row status policy (recorded in docs/project/tables/reconciliation.md):
  verified   unique match with score 1.00 (pattern) or a unique exact-byte
             hit (data). The stage-4 behavior gates (vsav2-as-oracle field
             comparison, dual-emulator agreement, crash guard) are the
             backstop that a wrong mapping cannot silently survive.
  plausible  best score < 1.00 or multiple close candidates — the
             generator refuses these until a human/deeper probe upgrades
             them (--allow-plausible exists for experiment builds only).
  open       no candidate found.

Usage:
    python3 tools/reconcile_batch.py <extract_dir> \
        --src $ROMDIR/vsav2.zip --dst $ROMDIR/vsavj.zip \
        [--out build/manifest/reconciliation.toml] [--window 0x40]

Merges with existing rows (existing rows win — hand-verified entries are
never overwritten).
"""

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cps2_decrypt as cps  # noqa: E402
import scan_code_refs  # noqa: E402
from _minitoml import loads as toml_loads  # noqa: E402


def plaintext_image(zpath):
    words, keybytes, prgs, sha1s = cps.load_set(zpath)
    cipher = cps.Cipher(keybytes)
    pt = cipher.transform(list(words), decrypt=True)
    return bytes(cps.words_to_logical_bytes(pt)), \
        bytes(cps.words_to_logical_bytes(words))


def masked_search(src_img, dst_img, addr, length):
    """find_equiv's core: wildcard operand bytes, anchor-search, score."""
    pat = bytearray(src_img[addr:addr + length])
    mask = bytearray(b"\x01" * len(pat))
    for ref in scan_code_refs.scan(bytes(pat), addr):
        if ref["how"] == "charid_imm":
            continue
        for i in range(ref["off"], min(ref["off"] + ref["width"] // 8, len(mask))):
            mask[i] = 0
    hard = mask.count(1)
    if hard < 8:
        return []
    best_run, cur = (0, 0), None
    for i, m in enumerate(list(mask) + [0]):
        if m and cur is None:
            cur = i
        elif not m and cur is not None:
            if i - cur > best_run[0]:
                best_run = (i - cur, cur)
            cur = None
    run_len, run_off = best_run
    anchor = bytes(pat[run_off:run_off + run_len])
    hits = []
    pos = dst_img.find(anchor)
    while pos != -1 and len(hits) < 64:
        base = pos - run_off
        if 0 <= base <= len(dst_img) - len(pat):
            score = sum(1 for i in range(len(pat))
                        if mask[i] and dst_img[base + i] == pat[i]) / hard
            hits.append((score, base))
        pos = dst_img.find(anchor, pos + 2)
    hits.sort(key=lambda h: (-h[0], h[1]))
    return hits


def _farm_entry(img, a):
    """Decode a `lea (d16,PC),A3; bra.w` stub at a -> (lea_target, bra_target)."""
    if int.from_bytes(img[a:a + 2], "big") == 0x47FA \
            and int.from_bytes(img[a + 4:a + 6], "big") == 0x6000:
        d1 = int.from_bytes(img[a + 2:a + 4], "big")
        d2 = int.from_bytes(img[a + 6:a + 8], "big")
        d1 -= 0x10000 if d1 >= 0x8000 else 0
        d2 -= 0x10000 if d2 >= 0x8000 else 0
        return a + 2 + d1, a + 6 + d2
    return None


_farm_cache = {}


def _farm_entries(img):
    """All farm-entry addresses in an image (cached)."""
    key = id(img)
    if key not in _farm_cache:
        out = []
        pos = img.find(b"\x47\xfa")
        while pos != -1:
            if pos % 2 == 0 and _farm_entry(img, pos):
                out.append(pos)
            pos = img.find(b"\x47\xfa", pos + 2)
        _farm_cache[key] = out
    return _farm_cache[key]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("extract_dir", type=Path)
    ap.add_argument("--src", type=Path, required=True)
    ap.add_argument("--dst", type=Path, required=True)
    root = Path(__file__).resolve().parent.parent
    ap.add_argument("--out", type=Path,
                    default=root / "build/manifest/reconciliation.toml")
    ap.add_argument("--window", type=lambda x: int(x, 0), default=0x40)
    args = ap.parse_args()

    man = json.loads((args.extract_dir / "regions.json").read_text())
    scan_by_off = {s["off"]: s for s in man.get("code_scan", [])}

    existing = {}
    if args.out.is_file():
        for m in toml_loads(args.out.read_text()).get("map", []):
            v = m["vsav2"] if isinstance(m["vsav2"], int) else int(m["vsav2"], 0)
            existing[v] = m

    # engine targets from EVERY code region (main + ported x-regions),
    # with their reference kinds (jsr/jmp => code)
    targets = {}
    for rname, region in man["regions"].items():
        for ref in region.get("refs", []):
            if ref.get("class") != "engine":
                continue
            how = (scan_by_off.get(ref["off"], {}).get("how", "bare_long")
                   if rname == "code" else "bare_long")
            targets.setdefault(ref["target"], set()).add(how)

    print(f"resolving {len(targets)} engine targets "
          f"({sum(1 for t in targets if t in existing)} already mapped)")
    print("decrypting images ...", file=sys.stderr)
    src_pt, src_data = plaintext_image(args.src)
    dst_pt, dst_data = plaintext_image(args.dst)

    def deref_stub(img, addr, depth=0):
        """Follow jmp-abs.l stubs to the real routine (stub farms are all
        operands — unsearchable; the underlying routine is. jsr stub ==
        jsr routine semantically)."""
        if depth >= 4:
            return addr
        w = int.from_bytes(img[addr:addr + 2], "big")
        if w == 0x4EF9:  # jmp abs.l
            return deref_stub(img, int.from_bytes(img[addr + 2:addr + 6], "big"),
                              depth + 1)
        if w == 0x6000:  # bra.w
            disp = int.from_bytes(img[addr + 2:addr + 4], "big")
            disp -= 0x10000 if disp >= 0x8000 else 0
            return deref_stub(img, addr + 2 + disp, depth + 1)
        return addr

    def pattern_resolve(tgt):
        """Window-retry masked search. Returns (cand, status, method)."""
        for win in (args.window, 0x30, 0x60, 0x80, 0x20):
            hits = masked_search(src_pt, dst_pt, tgt, win)
            if not hits:
                continue
            top = hits[0]
            unique = len(hits) == 1 or hits[1][0] < top[0] - 0.02
            if top[0] >= 0.999 and unique:
                return top[1], "verified", f"pattern-1.00-unique-w{win:#x}"
            if top[0] >= 0.90:
                return top[1], "plausible", f"pattern-{top[0]:.2f}-w{win:#x}"
        return None, "open", "-"

    rows = []
    stats = {"verified": 0, "plausible": 0, "open": 0, "kept": 0}
    for tgt in sorted(targets):
        if tgt in existing:
            rows.append(existing[tgt])
            stats["kept"] += 1
            continue
        hows = targets[tgt]
        is_code = bool(hows & {"jsr", "jmp"})
        cand, status, method = pattern_resolve(tgt)
        if status != "verified":
            final = deref_stub(src_pt, tgt)
            if final != tgt and final < 0x400000:
                c2, s2, m2 = pattern_resolve(final)
                if s2 == "verified":
                    # prefer the matching vsavj stub if one exists uniquely
                    stub = bytes([0x4E, 0xF9]) + c2.to_bytes(4, "big")
                    pos = dst_pt.find(stub)
                    if pos != -1 and dst_pt.find(stub, pos + 1) == -1:
                        cand, status, method = pos, "verified", \
                            f"stub-deref({final:#x})->{m2}+stubmatch"
                    else:
                        cand, status, method = c2, "verified", \
                            f"stub-deref({final:#x})->{m2}-direct"
                elif s2 != "open" and status == "open":
                    cand, status, method = c2, s2, f"stub-deref({final:#x})->{m2}"
        if status != "verified":
            # pass 3: call-site anchoring via veteran parallelism — the same
            # engine routine is referenced from shared (veteran/engine) code
            # present in BOTH games; pattern-match each vsav2 reference
            # site's context in vsavj and read the vsavj operand there.
            votes = {}
            for op_hex in (b"\x4e\xb9", b"\x4e\xf9", b"\x48\x79"):
                needle = op_hex + tgt.to_bytes(4, "big")
                pos = src_pt.find(needle)
                sites = 0
                while pos != -1 and sites < 8:
                    if not (0x057000 <= pos < 0x05D000):  # skip newcomer code
                        ctx_start = max(0, pos - 0x1E)
                        hits = masked_search(src_pt, dst_pt, ctx_start, 0x40)
                        if hits and hits[0][0] >= 0.999 and \
                                (len(hits) == 1 or hits[1][0] < hits[0][0] - 0.02):
                            dbase = hits[0][1] + (pos - ctx_start)
                            if dst_pt[dbase:dbase + 2] == op_hex:
                                v = int.from_bytes(dst_pt[dbase + 2:dbase + 6], "big")
                                votes[v] = votes.get(v, 0) + 1
                        sites += 1
                    pos = src_pt.find(needle, pos + 2)
            if votes:
                top_v = max(votes, key=votes.get)
                if votes[top_v] == sum(votes.values()):
                    cand, status, method = top_v, "verified", \
                        f"callsite-anchored-x{votes[top_v]}"
                else:
                    cand, status, method = top_v, "plausible", \
                        f"callsite-votes-{votes}"
        if status != "verified":
            # pass 4: exact plaintext-byte search — position-independent
            # engine stubs (PC-relative farm entries, tiny A6-offset
            # predicate helpers) carry no absolute operands; if the block's
            # internal layout is preserved, their bytes recur verbatim.
            for wlen in (0x18, 0x10, 0x8):
                win = src_pt[tgt:tgt + wlen]
                pos = dst_pt.find(win)
                if pos != -1 and dst_pt.find(win, pos + 1) == -1:
                    cand, status, method = pos, "verified", \
                        f"codebytes-unique-w{wlen:#x}"
                    break
        if status != "verified":
            # pass 5: predicate-stub-farm matching. Farm entries are
            # `lea (d16,PC),A3; bra.w common` — pure PC-relative, and the
            # farms differ in SIZE between games (vsav2 added entries), so
            # neither pattern nor index mapping works. But each entry's lea
            # points to a tiny helper whose bytes (A6 offset + bit number)
            # are game-independent semantics: match entries by identical
            # helper content.
            # NB: the lea target is a DATA parameter block (read via the
            # data path, never opcode-fetched) — compare raw stored bytes,
            # not the plaintext view.
            ent = _farm_entry(src_pt, tgt)
            if ent:
                helper = src_data[ent[0]:ent[0] + 8]
                matches = []
                for base in _farm_entries(dst_pt):
                    e2 = _farm_entry(dst_pt, base)
                    if e2 and dst_data[e2[0]:e2[0] + 8] == helper:
                        matches.append(base)
                if len(matches) == 1:
                    cand, status, method = matches[0], "verified", \
                        "farm-helper-match"
                elif len(matches) > 1:
                    cand, status, method = matches[0], "plausible", \
                        f"farm-helper-x{len(matches)}"
        if cand is None and not is_code:
            win = src_data[tgt:tgt + 0x20]
            pos = dst_data.find(win)
            if pos != -1 and dst_data.find(win, pos + 1) == -1:
                cand, status, method = pos, "verified", "databytes-unique"
        row = {"vsav2": tgt, "vsavj": cand if cand is not None else 0,
               "kind": "engine_sub" if is_code else "engine_data",
               "status": status,
               "note": f"{method}; refs: {','.join(sorted(hows))}"}
        rows.append(row)
        stats[status] += 1

    # preserve existing rows whose targets are not in the engine list
    # (hand-added bank_ref/data rows must survive regeneration)
    for v, m in existing.items():
        if v not in targets:
            rows.append(m)
            stats["kept"] += 1

    lines = ["# reconciliation.toml — R1 map (vsav2 -> vsavj). Generated rows",
             "# by tools/reconcile_batch.py; hand-verified rows are kept as-is.",
             "# Twin doc: docs/project/tables/reconciliation.md (same-commit rule)."]
    def _fmt(k, v):
        if isinstance(v, int):
            return f"{k} = {v:#08x}"
        if isinstance(v, str) and k not in ("kind", "status", "note",
                                            "param_hex"):
            try:
                return f"{k} = {int(v, 0):#08x}"
            except ValueError:
                pass
        return f'{k} = "{v}"'

    for r in rows:
        lines += ["", "[[map]]"]
        for k in ("vsav2", "vsavj", "kind", "status"):
            lines.append(_fmt(k, r[k]))
        for k, v in r.items():  # preserve extra keys (param_hex, common, ...)
            if k not in ("vsav2", "vsavj", "kind", "status", "note"):
                lines.append(_fmt(k, v))
        lines.append(f'note = "{r.get("note", "")}"')
    args.out.write_text("\n".join(lines) + "\n")
    print(f"wrote {args.out}: {stats}")
    if stats["open"] or stats["plausible"]:
        print("unresolved rows remain — the stage-4 generator will list them")


if __name__ == "__main__":
    main()
