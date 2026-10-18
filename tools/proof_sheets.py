#!/usr/bin/env python3
"""proof_sheets.py — the comparative capture sheets: a visual proof of accuracy for humans (GitHub #291, slice S1,
14z-204; the design ruled 2026-10-16/17, DECISIONS_HISTORY.md "Ruled 2026-10-16 (14z-203) — #291 …" and
"Ruled 2026-10-17 (14z-203) — … #291's design (four answers)").

WHAT IT DOES. For every comparing gate that declares itself (`# SHEET: legs ...` in its leading comment block), it
runs the gate with SHEET_OUT set, so the gate writes the legs it ran and the moments it judged (tests/lib/sheet.sh);
re-runs each leg with tests/lua/sheet_capture.lua, photographing it at each moment; PROVES each picture against what
the gate logged there (its checksum log, a checksum, or the fields it compared); and writes ONE page,
build/sheets/<commit>/index.html, indexed by test, by character and by ticket. A picture that cannot be proven is
shown as NOT THE JUDGED RUN, never silently ([VSP-19]: tests/test_proof_sheets.sh is this tool's ground truth).

THE DECLARATION, read the way `# MUST-FIRE:` is (one line in the leading comment block):
    # SHEET: legs ours,vs2 — moments: <what the gate judges> — not comparable: <what differs by design>
    # SHEET: no-reference-leg — <reason>   (our build against frozen values, no rig of the other game: listed, not drawn)
    # SHEET: no-picture — <reason>         (the gate compares legs, but what it judges cannot be shown as a proven
                                           picture: a corpus-wide summary, a -debug run, a run outside the gate script,
                                           an FBNeo leg; ruled 2026-10-18, D4: listed, not drawn)
    # SHEET: none — <reason>               (the gate compares no leg of ours against a reference set)
A `legs` gate must source tests/lib/sheet.sh. tests/test_sheet_census.sh holds every emulator-registry gate to one
well-formed line, against a shrink-only debt list (tests/expected/sheet_debt.txt): the S2 retrofit's work list.

SLICE S1 BOUNDS (said, not hidden): the commit must be HEAD, and the builds are the ones the gates default to (or the
runner's %PLACEHOLDER% defaults) — building that commit in a clean checkout is slice S3, as are --host pilot|eris.

Usage:
    proof_sheets.py run [<commit>] [--gate G]... [--char C] [--ticket N] [--jobs N] [--out DIR]
    proof_sheets.py prove <sheet_out dir> [--jobs N]       re-run, photograph and prove one gate's SHEET_OUT
    proof_sheets.py page <out dir>                         re-draw the page from proven sheets
    proof_sheets.py census [--tests DIR] [--registry F] [--debt F]
Env: ROMDIR (required for run/prove), MAME_BIN.
"""
import concurrent.futures, glob, html, json, os, re, shutil, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ROLES = ("vs2", "vsavj", "ours")          # row order on a sheet: native vs2 on top, then vsavj, then ours (#177)
BASES = ("log", "ram", "fields", "file", "event", "none")
DECL = re.compile(r"^#\s*SHEET:\s*(.*)$")
DASH = re.compile(r"\s+(?:—|--)\s+")


# ── the declaration ─────────────────────────────────────────────────────────────────────────────────────────────
def leading_block(path):
    """The gate's leading comment block: every `#` line after the shebang up to the first non-comment line (a blank
    line is one; a bare `#` continues it) — the must-fire reader's definition (docs/project/gate_header_contract.md)."""
    out = []
    for i, line in enumerate(Path(path).read_text(errors="replace").splitlines()):
        if i == 0 and line.startswith("#!"):
            continue
        if line.startswith("#"):
            out.append(line)
            continue
        break
    return out


def parse_declaration(path):
    """-> (decl dict | None, error | None). None, None = no declaration."""
    lines = [m.group(1).strip() for m in (DECL.match(l) for l in leading_block(path)) if m]
    if not lines:
        return None, None
    if len(lines) > 1:
        return None, "%d `# SHEET:` lines (one is allowed)" % len(lines)
    body = lines[0]
    parts = DASH.split(body)
    head = parts[0].strip()
    if head in ("none", "no-reference-leg", "no-picture"):
        if len(parts) < 2 or not " ".join(parts[1:]).strip():
            return None, "`# SHEET: %s` needs a reason after the dash" % head
        return {"kind": head, "reason": " — ".join(p.strip() for p in parts[1:])}, None
    m = re.match(r"^legs\s+([a-z0-9,]+)$", head)
    if not m:
        return None, "the line must start `legs <roles>`, `none —`, `no-reference-leg —` or `no-picture —` (got %r)" % head[:40]
    roles = m.group(1).split(",")
    bad = [r for r in roles if r not in ROLES]
    if bad:
        return None, "unknown role(s) %s (roles: %s)" % (",".join(bad), ",".join(ROLES))
    if "ours" not in roles or not ({"vsavj", "vs2"} & set(roles)):
        return None, "a legs declaration names `ours` and at least one of vsavj, vs2"
    fields = {}
    for p in parts[1:]:
        k, _, v = p.partition(":")
        fields[k.strip()] = v.strip()
    for need in ("moments", "not comparable"):
        if not fields.get(need):
            return None, "a legs declaration needs `— %s: <text>`" % need
    return {"kind": "legs", "roles": roles, "moments": fields["moments"], "not_comparable": fields["not comparable"]}, None


def sources_sheet_lib(path):
    """A code line (not a comment) that sources tests/lib/sheet.sh."""
    for line in Path(path).read_text(errors="replace").splitlines():
        s = line.strip()
        if s.startswith("#"):
            continue
        if re.search(r"(^|[;&|]\s*|\s)\.\s+\S*tests/lib/sheet\.sh", s) or re.search(r"\bsource\s+\S*tests/lib/sheet\.sh", s):
            return True
    return False


def registry_gates(registry):
    out = []
    for line in Path(registry).read_text().splitlines():
        if line.startswith("#") or not line.strip():
            continue
        f = line.split("\t")
        if len(f) >= 3 and f[0]:
            out.append(f)
    return out


def read_debt(debt):
    if not Path(debt).exists():
        return None
    return [l.strip() for l in Path(debt).read_text().splitlines() if l.strip() and not l.startswith("#")]


def census(tests, registry, debt):
    """-> (rows, problems). rows: (gate, class) with class legs|none|no-reference-leg|no-picture|debt."""
    gates = [r[0] for r in registry_gates(registry)]
    owed = read_debt(debt)
    problems, rows = [], []
    if owed is None:
        return rows, ["no debt list at %s" % debt]
    owed_set = set(owed)
    if len(owed) != len(owed_set):
        problems.append("the debt list names a gate twice")
    for g in gates:
        p = Path(tests) / (g + ".sh")
        if not p.exists():
            problems.append("%s: registered but no %s" % (g, p))
            continue
        d, err = parse_declaration(p)
        if err:
            problems.append("%s: %s" % (g, err))
            continue
        if d is None:
            if g in owed_set:
                rows.append((g, "debt"))
            else:
                problems.append("%s: no `# SHEET:` line and not in the debt list — declare it" % g)
            continue
        if g in owed_set:
            problems.append("%s: declares `# SHEET: %s` but is still in the debt list — remove it (the list only shrinks)" % (g, d["kind"]))
        if d["kind"] == "legs" and not sources_sheet_lib(p):
            problems.append("%s: declares legs but never sources tests/lib/sheet.sh — it would write no sheet" % g)
        rows.append((g, d["kind"]))
    for g in sorted(owed_set - set(gates)):
        problems.append("%s: in the debt list but not an emulator-registry gate — remove it" % g)
    return rows, problems


# ── the sheet file ──────────────────────────────────────────────────────────────────────────────────────────────
WIDTH = {"sheet": 6, "leg": 11, "moment": 6, "at": 7, "anchors": 2, "tap": 5}


def read_sheet(d):
    """tests/lib/sheet.sh's file -> {sid: sheet}. Refuses a malformed row (raises ValueError)."""
    p = Path(d) / "sheet.tsv"
    sheets, order = {}, []
    for n, line in enumerate(p.read_text().splitlines(), 1):
        f = line.split("\t")
        kind = f[0]
        if kind not in WIDTH or len(f) != WIDTH[kind]:
            raise ValueError("sheet.tsv:%d: %r row with %d fields" % (n, kind, len(f)))
        sid = f[1]
        if kind == "sheet":
            if sid in sheets:
                raise ValueError("sheet.tsv:%d: sheet %s declared twice" % (n, sid))
            sheets[sid] = {"sid": sid, "title": f[2], "chars": [] if f[3] == "-" else f[3].split(","),
                           "tickets": [] if f[4] == "-" else f[4].split(","), "not_comparable": f[5],
                           "legs": {}, "moments": {}, "mids": [], "anchors": False}
            order.append(sid)
            continue
        if sid not in sheets:
            raise ValueError("sheet.tsv:%d: %s row for undeclared sheet %s" % (n, kind, sid))
        s = sheets[sid]
        if kind == "leg":
            if f[3] not in ROLES:
                raise ValueError("sheet.tsv:%d: role %r" % (n, f[3]))
            s["legs"][f[2]] = {"leg": f[2], "role": f[3], "set": f[4], "rompath": f[5], "replay": f[6],
                               "pokes": "" if f[7] == "-" else f[7], "frames": int(f[8]),
                               "log": None if f[9] == "-" else f[9], "mask": "" if f[10] == "-" else f[10]}
        elif kind == "moment":
            s["moments"][f[2]] = {"mid": f[2], "label": f[3], "verdict": f[4], "values": f[5], "at": {}}
            s["mids"].append(f[2])
        elif kind == "at":
            if f[2] not in s["moments"]:
                raise ValueError("sheet.tsv:%d: at-row for undeclared moment %s" % (n, f[2]))
            if f[3] not in s["legs"]:
                raise ValueError("sheet.tsv:%d: at-row for undeclared leg %s" % (n, f[3]))
            if f[5] not in BASES:
                raise ValueError("sheet.tsv:%d: basis %r" % (n, f[5]))
            s["moments"][f[2]]["at"][f[3]] = {"frame": int(f[4]), "basis": f[5], "expect": f[6]}
        elif kind == "anchors":
            s["anchors"] = True
        elif kind == "tap":
            if f[2] not in s["legs"]:
                raise ValueError("sheet.tsv:%d: tap row for undeclared leg %s" % (n, f[2]))
            env, last = {}, None
            for kv in ([] if f[4] == "-" else f[4].split(";")):
                k, eq, v = kv.partition("=")
                if eq and re.match(r"^[A-Z_][A-Z0-9_]*$", k):
                    env[k] = v; last = k
                elif last is not None:
                    env[last] += ";" + kv      # a value with its own ';' (read_tap's RTAP joins ranges with ';')
                else:
                    raise ValueError("sheet.tsv:%d: tap env entry %r is not NAME=value" % (n, kv))
            s["legs"][f[2]]["tap"] = {"script": f[3], "env": env}
    return [sheets[k] for k in order]


def read_log(path):
    out = {}
    for line in Path(path).read_text().splitlines():
        t = line.split()
        if len(t) == 2 and t[0].isdigit():
            out[int(t[0])] = t[1]
    return out


def parse_fields(spec):
    out = {}
    for kv in spec.split(","):
        k, _, v = kv.partition("=")
        if not re.match(r"^[0-9a-f]+:[bwl]$", k.strip().lower()) or not re.match(r"^-?\d+$", v.strip()):
            raise ValueError("fields expectation %r" % kv)
        out[k.strip().lower()] = int(v)
    return out


# ── capture and prove ───────────────────────────────────────────────────────────────────────────────────────────
def capture(sheet_dir, s, leg, work):
    """Run one leg under sheet_capture.lua; -> {"C": {frame: hex}, "V": {frame: {spec: v}}, "A": [(frame, label)],
    "S": {frame: png}, "error": str|None}."""
    lg = s["legs"][leg]
    frames = sorted({a["frame"] for m in s["moments"].values() for l, a in m["at"].items() if l == leg and a["basis"] != "file"})
    specs = sorted({k for m in s["moments"].values() for l, a in m["at"].items()
                    if l == leg and a["basis"] == "fields" for k in parse_fields(a["expect"])})
    res = {"C": {}, "V": {}, "A": [], "S": {}, "T": None, "error": None, "capped": None}
    if not frames and not s["anchors"]:
        return res
    w = Path(work) / ("%s.%s" % (s["sid"], leg))
    shutil.rmtree(w, ignore_errors=True)
    w.mkdir(parents=True)
    if lg.get("tap"):
        return capture_tap(sheet_dir, lg, frames, w, res)
    env = dict(os.environ, MAME_SANDBOX=str(w / "sb"), MAME_ROMPATH=lg["rompath"],
               REPLAY=str(Path(sheet_dir) / lg["replay"]), POKES=lg["pokes"], MASK_RANGES=lg["mask"],
               SNAP_FRAMES=",".join(map(str, frames)), FIELDS=",".join(specs), CAPTURE_OUT=str(w / "cap.txt"),
               FRAMES=str(lg["frames"] if s["anchors"] else max(frames) + 1), ANCHORS="1" if s["anchors"] else "")
    for k in ("POKES", "MASK_RANGES", "FIELDS", "ANCHORS"):
        if not env[k]:
            env.pop(k)
    with open(w / "mame.log", "w") as lf:
        subprocess.run([str(ROOT / "tools/run_mame.sh"), lg["set"], "-autoboot_script",
                        str(ROOT / "tests/lua/sheet_capture.lua")], env=env, cwd=w, stdout=lf, stderr=subprocess.STDOUT,
                       stdin=subprocess.DEVNULL)
    cap = w / "cap.txt"
    if not cap.exists() or "CAPSUMMARY" not in cap.read_text():
        res["error"] = "the capture run did not finish (%s)" % (w / "mame.log")
        return res
    snaps = sorted(glob.glob(str(w / "sb" / "snap" / "*" / "*.png")))
    for line in cap.read_text().splitlines():
        t = line.split(" ", 2)
        if t[0] == "C":
            res["C"][int(t[1])] = t[2]
        elif t[0] == "V":
            res["V"][int(t[1])] = parse_fields(t[2])
        elif t[0] == "A":
            res["A"].append((int(t[1]), t[2]))
        elif t[0] == "ACAP":
            res["capped"] = "anchors capped by ANCHOR_MAX: the next, %s at f%s, and any after it are not drawn" % (t[2], t[1])
        elif t[0] == "S":
            n, fr = int(t[1]), int(t[2])
            png = w / "sb" / "snap"
            hit = [p for p in snaps if os.path.basename(p) == "%04d.png" % n]
            if hit:
                res["S"][fr] = hit[0]
    return res


def capture_tap(sheet_dir, lg, frames, w, res):
    """D2 (ruled 2026-10-18): re-run a tap leg under its gate's own instrument (tests/lua/sheet_tap_capture.lua), with the
    gate's env, its replay and pokes; photograph at the moment frames; keep the instrument's re-run log for the event proof."""
    tap = lg["tap"]
    env = dict(os.environ, **tap["env"])
    env.update(MAME_SANDBOX=str(w / "sb"), MAME_ROMPATH=lg["rompath"], REPLAY=str(Path(sheet_dir) / lg["replay"]),
               TAP_SCRIPT=str(ROOT / tap["script"]), SNAP_FRAMES=",".join(map(str, frames)), WRAP_OUT=str(w / "wrap.txt"),
               TRACE_OUT=str(w / "tap.txt"), FIELD_OUT=str(w / "tap.txt"))   # rom_poke.lua hands off to field_trace.lua (FIELD_OUT)
    if lg["pokes"]:
        env["POKES"] = lg["pokes"]
    else:
        env.pop("POKES", None)
    with open(w / "mame.log", "w") as lf:
        subprocess.run([str(ROOT / "tools/run_mame.sh"), lg["set"], "-autoboot_script",
                        str(ROOT / "tests/lua/sheet_tap_capture.lua")], env=env, cwd=w, stdout=lf, stderr=subprocess.STDOUT,
                       stdin=subprocess.DEVNULL)
    if not (w / "tap.txt").exists() or not (w / "wrap.txt").exists():
        res["error"] = "the tap re-run did not finish (%s)" % (w / "mame.log")
        return res
    snaps = sorted(glob.glob(str(w / "sb" / "snap" / "*" / "*.png")))
    for line in (w / "wrap.txt").read_text().splitlines():
        t = line.split()
        if len(t) == 3 and t[0] == "S":
            hit = [p for p in snaps if os.path.basename(p) == "%04d.png" % int(t[1])]
            if hit:
                res["S"][int(t[2])] = hit[0]
    res["T"] = str(w / "tap.txt")
    return res


TAPFRAME = re.compile(r"^[Ff]?(\d+)$")


def tap_lines(path, lo, hi):
    """The instrument log's lines whose frame (the first of the first two tokens reading `N`, `fN` or `FN`) is in
    [lo, hi]: `W 7 PC …`, `f2197 id …`, `F f2197 e07 …`, `F2197 B0 E000 …`, `== f2197 id 0700 ==`."""
    out = []
    for line in Path(path).read_text(errors="replace").splitlines():
        if line.split()[:1] and (line.split()[0] in ("END", "PCHIST", "OPATCH") or line.split()[0].endswith("SUMMARY")):
            continue                     # a run summary, not an event
        for tok in line.split()[:2]:
            m = TAPFRAME.match(tok)
            if m:
                if lo <= int(m.group(1)) <= hi:
                    out.append(line.rstrip())
                break
    return out


def prove(at, lg, cap, sheet_dir):
    """-> (status, why). status: PROVEN | NOT THE JUDGED RUN | JUDGED FILE | UNPROVEN."""
    fr, basis, exp = at["frame"], at["basis"], at["expect"]
    if basis == "file":
        return "JUDGED FILE", "the picture the gate itself compared (%s)" % exp
    if basis == "none":
        return "UNPROVEN", "the gate logged nothing that can prove this picture"
    if fr not in cap["S"]:
        return "NOT THE JUDGED RUN", "no snapshot at f%d" % fr
    if basis == "event":
        m = re.match(r"^(.+):(\d+)-(\d+)$", exp)
        if not m:
            return "NOT THE JUDGED RUN", "an event expectation is <log>:<lo>-<hi>, not %r" % exp
        if not cap.get("T"):
            return "NOT THE JUDGED RUN", "the leg has no tap row, so it was not re-run under its instrument"
        lo, hi = int(m.group(2)), int(m.group(3))
        want, got = tap_lines(Path(sheet_dir) / m.group(1), lo, hi), tap_lines(cap["T"], lo, hi)
        if not want:
            return "UNPROVEN", "the gate logged no event in f%d-%d: nothing to prove the picture by" % (lo, hi)
        if want == got:
            return "EVENT-PROVEN", "the %d event line(s) the gate logged in f%d-%d are reproduced exactly; work RAM outside the tapped addresses is not proven" % (len(want), lo, hi)
        diff = next((i for i in range(max(len(want), len(got))) if (want[i:i + 1] or [None]) != (got[i:i + 1] or [None])), 0)
        return "NOT THE JUDGED RUN", "in f%d-%d the re-run logs %d event line(s) against the gate's %d; first difference: gate %r, re-run %r" % (
            lo, hi, len(got), len(want), (want[diff:diff + 1] or ["-"])[0][:60], (got[diff:diff + 1] or ["-"])[0][:60])
    if basis in ("log", "ram"):
        if basis == "log":
            if not lg["log"]:
                return "NOT THE JUDGED RUN", "basis log but the leg carries no log"
            exp = read_log(Path(sheet_dir) / lg["log"]).get(fr)
            if exp is None:
                return "NOT THE JUDGED RUN", "the gate's log has no f%d" % fr
        got = cap["C"].get(fr)
        mask = " (masked %s)" % lg["mask"] if lg["mask"] else ""
        if got == exp:
            return "PROVEN", "work RAM%s at f%d equals the gate's %s" % (mask, fr, "log" if basis == "log" else "checksum")
        return "NOT THE JUDGED RUN", "work RAM%s at f%d is %s, the gate's %s" % (mask, fr, got, exp)
    want = parse_fields(exp)
    got = cap["V"].get(fr, {})
    off = [k for k in want if got.get(k) != want[k]]
    if off:
        return "NOT THE JUDGED RUN", "at f%d %s" % (fr, ", ".join("%s is %s, the gate's %s" % (k, got.get(k), want[k]) for k in off[:4]))
    return "PROVEN", "the %d compared field(s) at f%d equal the gate's" % (len(want), fr)


def prove_dir(sheet_dir, jobs=4):
    """Capture and prove every sheet of one gate's SHEET_OUT; writes proof.json beside it and returns it."""
    sheet_dir = Path(sheet_dir).resolve()  # each capture runs in its own work dir: a relative path would not resolve there
    sheets = read_sheet(sheet_dir)
    work = sheet_dir / "capture"
    tasks = [(s, leg) for s in sheets for leg in s["legs"]]
    caps = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, jobs)) as ex:
        futs = {ex.submit(capture, sheet_dir, s, leg, work): (s["sid"], leg) for s, leg in tasks}
        for fu in concurrent.futures.as_completed(futs):
            caps[futs[fu]] = fu.result()
    out = []
    for s in sheets:
        legs = sorted(s["legs"].values(), key=lambda l: (ROLES.index(l["role"]), l["leg"]))
        cols = []
        for mid in s["mids"]:
            m = s["moments"][mid]
            cells = {}
            for lg in legs:
                at = m["at"].get(lg["leg"])
                if not at:
                    continue
                cap = caps[(s["sid"], lg["leg"])]
                st, why = ("NOT THE JUDGED RUN", cap["error"]) if cap["error"] and at["basis"] != "file" else prove(at, lg, cap, sheet_dir)
                pic = str(sheet_dir / at["expect"]) if at["basis"] == "file" else cap["S"].get(at["frame"])
                cells[lg["leg"]] = {"frame": at["frame"], "status": st, "why": why, "pic": pic}
            cols.append({"label": m["label"], "verdict": m["verdict"], "values": m["values"], "cells": cells})
        if s["anchors"]:
            ref = legs[0]["leg"]
            for k, (fr, label) in enumerate(caps[(s["sid"], ref)]["A"]):
                cells = {}
                for lg in legs:
                    cap = caps[(s["sid"], lg["leg"])]
                    if k >= len(cap["A"]):
                        cells[lg["leg"]] = {"frame": None, "status": "NOT THE JUDGED RUN", "why": "this leg has no anchor %d" % (k + 1), "pic": None}
                        continue
                    afr, alabel = cap["A"][k]
                    st, why = prove({"frame": afr, "basis": "log", "expect": "-"}, lg, cap, sheet_dir)
                    if (afr, alabel) != (fr, label):
                        why += "; this leg's anchor %d is %s at f%d" % (k + 1, alabel, afr)
                    cells[lg["leg"]] = {"frame": afr, "status": st, "why": why, "pic": cap["S"].get(afr)}
                cols.append({"label": "anchor: " + label, "verdict": "-", "values": "-", "cells": cells})
        capped = [("%s: %s" % (lg["leg"], caps[(s["sid"], lg["leg"])]["capped"])) for lg in legs
                  if caps[(s["sid"], lg["leg"])]["capped"]]
        out.append({"sid": s["sid"], "title": s["title"], "chars": s["chars"], "tickets": s["tickets"],
                    "not_comparable": s["not_comparable"], "capped": capped,
                    "legs": [{"leg": l["leg"], "role": l["role"], "set": l["set"], "rompath": l["rompath"]} for l in legs],
                    "cols": cols})
    (sheet_dir / "proof.json").write_text(json.dumps(out, indent=1))
    return out


# ── running the gates ───────────────────────────────────────────────────────────────────────────────────────────
def runner_defaults():
    txt = (ROOT / "tests/run_all_emulator.sh").read_text()
    return dict(re.findall(r'^(MERGED|DON|HUI|PYR|STOCK)="\$\{\w+:-([^}]*)\}"', txt, re.M))


def expand(s, d):
    for k in ("MERGED", "DON", "HUI", "PYR", "STOCK"):
        s = s.replace("%%%s_RP%%" % k, d[k] + "/rompath").replace("%%%s%%" % k, d[k])
    return s


def verdict_line(text):
    """The gate's verdict line: the last one starting PASS/FAIL/SKIP; else the last whose leading words end in PASS,
    FAIL or SKIP (`AUDIT PASS`, `FLICKER ATTRIBUTION: PASS`, `audit_trap_shock: PASS (...)`, 14z-205), never a
    CONTROL FIRED/DEAD line or an indented one."""
    lines = text.splitlines()
    hit = next((l for l in reversed(lines) if re.match(r"^(PASS|FAIL|SKIP)\b", l)), None)
    if hit is None:
        hit = next((l for l in reversed(lines) if not l.startswith(("CONTROL ", " ", "\t"))
                    and re.match(r"^[A-Za-z0-9_ .-]{0,40}?:?\s?(PASS|FAIL|SKIP)\b", l)), None)
    return hit or "no verdict line"


def run_gate(row, sheet_dir, log):
    gate, args = row[0], row[4] if len(row) > 4 else "-"
    tmo = int(row[6]) if len(row) > 6 and row[6].strip().isdigit() else 5400
    env, pos = dict(os.environ, SHEET_OUT=str(sheet_dir)), []
    if args.strip() not in ("", "-"):
        for tok in expand(args, runner_defaults()).split():
            if re.match(r"^[A-Z_][A-Z0-9_]*=", tok) and not pos:
                k, _, v = tok.partition("=")
                env[k] = v
            else:
                pos.append(tok)
    shutil.rmtree(sheet_dir, ignore_errors=True)
    Path(sheet_dir).mkdir(parents=True)
    t0 = time.time()
    with open(log, "w") as lf:
        try:
            rc = subprocess.run([str(ROOT / "tests" / (gate + ".sh"))] + pos, env=env, cwd=ROOT, stdout=lf,
                                stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, timeout=tmo).returncode
        except subprocess.TimeoutExpired:
            rc = 124
    verdict = verdict_line(Path(log).read_text(errors="replace"))
    return {"gate": gate, "rc": rc, "verdict": verdict[:200], "seconds": int(time.time() - t0)}


def select(rows, gates, char, ticket):
    picked = []
    tickets_where = {}
    tsv = ROOT / "docs/project/tickets.tsv"
    if ticket and tsv.exists():
        for line in tsv.read_text().splitlines():
            f = line.split("\t")
            if f and f[0] == str(ticket) and len(f) > 4:
                tickets_where = set(re.findall(r"tests/(\w+)\.sh", f[4]))
    for r in rows:
        g = r[0]
        p = ROOT / "tests" / (g + ".sh")
        if gates and g not in gates:
            continue
        head = "\n".join(leading_block(p)) if p.exists() else ""
        if char and char.lower() not in (g + head).lower():
            continue
        if ticket and not (re.search(r"#%s\b" % ticket, head) or g in tickets_where):
            continue
        picked.append(r)
    return picked


# ── the page ────────────────────────────────────────────────────────────────────────────────────────────────────
CSS = """
:root{--link:#1f5fa8;--bg:#fafaf8;--fg:#1d1d1b;--mut:#6b6b66;--line:#d9d8d2;--ok:#2f7d32;--diff:#b26a00;--bad:#c62828;--card:#fff}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){--link:#8ab4f8;--bg:#161615;--fg:#ecebe6;--mut:#a3a29c;--line:#3a3935;--ok:#7bc47f;--diff:#f0a640;--bad:#ef6b6b;--card:#1f1f1d}}
:root[data-theme="dark"]{--link:#8ab4f8;--bg:#161615;--fg:#ecebe6;--mut:#a3a29c;--line:#3a3935;--ok:#7bc47f;--diff:#f0a640;--bad:#ef6b6b;--card:#1f1f1d}
body{background:var(--bg);color:var(--fg);font:14px/1.45 system-ui,sans-serif;margin:0;padding:16px}
h1{font-size:20px;margin:0 0 4px} h2{font-size:16px;margin:28px 0 6px} .mut{color:var(--mut)}
.sheet{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:12px;margin:14px 0;overflow-x:auto}
table.grid{border-collapse:collapse} .grid td,.grid th{padding:4px;vertical-align:top;text-align:left}
.cell img{display:block;width:192px;height:auto;border:3px solid transparent}
.PROVEN img{border-color:transparent} .DIFF img{border-color:var(--diff)}
.NOTJUDGED img{border:3px dashed var(--bad)} .cap{font-size:11px;max-width:192px} .st{font-weight:600}
.st.PROVEN{color:var(--ok)} .st.NOTJUDGED{color:var(--bad)} .st.UNPROVEN{color:var(--diff)} .st.EVENT-PROVEN{color:var(--ok);font-style:italic}
.idx a{margin-right:10px} a{color:var(--link)} .nc{font-size:12px;margin-top:6px}
.note{background:var(--card);border-left:3px solid var(--link);padding:6px 12px;margin:6px 0 10px;max-width:900px}
.note p{margin:6px 0} .note ul{margin:4px 0 6px 18px;padding:0}
"""


NOTES = ROOT / "docs/project/sheet_notes.md"
REPO_URL = "https://github.com/DefinitelyFrenchName/VampireSaved/issues/"


def sheet_notes(path=NOTES):
    """docs/project/sheet_notes.md -> {gate: text}: each `## <gate>` section's body (14z-205, #291)."""
    notes, cur = {}, None
    if not Path(path).exists():
        return notes
    for line in Path(path).read_text().splitlines():
        m = re.match(r"^## +`?([A-Za-z0-9_]+)`?\s*$", line)
        if m:
            cur = m.group(1)
            notes[cur] = []
        elif line.startswith("#"):
            cur = None
        elif cur:
            notes[cur].append(line)
    return {g: "\n".join(t).strip() for g, t in notes.items()}


def note_html(text):
    """A note's paragraphs and `- ` bullets as HTML: **bold**, `code` and #N (a link to the issue); all else escaped."""
    def inline(t):
        t = html.escape(t)
        t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)
        t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", t)
        return re.sub(r"(?<![\w/&])#(\d+)\b", lambda m: '<a href="%s%s">#%s</a>' % (REPO_URL, m.group(1), m.group(1)), t)
    out, para, items = [], [], []
    def flush():
        if para:
            out.append("<p>%s</p>" % inline(" ".join(para))); para.clear()
        if items:
            out.append("<ul>%s</ul>" % "".join("<li>%s</li>" % inline(i) for i in items)); items.clear()
    for line in text.splitlines():
        if not line.strip():
            flush()
        elif line.lstrip().startswith("- "):
            if para:
                flush()
            items.append(line.lstrip()[2:].strip())
        elif items and line.startswith("  "):
            items[-1] += " " + line.strip()
        else:
            if items:
                flush()
            para.append(line.strip())
    flush()
    return "".join(out)


def page(out_dir, meta):
    out_dir = Path(out_dir)
    pics = out_dir / "pics"
    pics.mkdir(exist_ok=True)
    body, by_char, by_ticket, by_test = [], {}, {}, []
    notes = sheet_notes()
    for g in meta["gates"]:
        gid = g["gate"]
        by_test.append(gid)
        body.append('<h2 id="%s">%s</h2><div class="mut">gate verdict: %s (%ss)</div>' % (
            gid, html.escape(gid), html.escape(g["verdict"]), g["seconds"]))
        if gid in notes:
            body.append('<div class="note">%s</div>' % note_html(notes[gid]))
        for s in g.get("sheets", []):
            anchor = "%s--%s" % (gid, s["sid"])
            for c in s["chars"]:
                by_char.setdefault(c, []).append(anchor)
            for t in s["tickets"] + g.get("tickets", []):
                by_ticket.setdefault(t.lstrip("#"), []).append(anchor)
            # one timeline: the declared moments and the anchors, by frame (the first leg's frame that is known)
            s["cols"] = sorted(s["cols"], key=lambda c: min([x["frame"] for x in c["cells"].values() if x["frame"] is not None] or [0]))
            rows = []
            head = "".join('<th class="cap">%s<br><span class="mut">%s</span></th>' % (
                html.escape(c["label"]), html.escape(c["verdict"])) for c in s["cols"])
            for lg in s["legs"]:
                tds = []
                for k, c in enumerate(s["cols"]):
                    cell = c["cells"].get(lg["leg"])
                    if not cell:
                        tds.append("<td></td>")
                        continue
                    cls = "NOTJUDGED" if cell["status"] == "NOT THE JUDGED RUN" else (
                        "DIFF" if re.match(r"(?i)^(DIFF|FAIL|DIVERGE)", c["verdict"]) else "PROVEN")
                    img = ""
                    if cell["pic"] and os.path.exists(cell["pic"]):
                        ext = os.path.splitext(cell["pic"])[1].lower() or ".png"
                        name = "%s.%s.%s.%d%s" % (gid, s["sid"], lg["leg"], k, ext)
                        shutil.copyfile(cell["pic"], pics / name)
                        if ext in (".wav", ".ogg", ".mp3"):   # the ruled sound clips (2026-10-17): the gate's own recording
                            img = '<audio controls preload="none" src="pics/%s"></audio>' % html.escape(name)
                        else:
                            img = '<img src="pics/%s" alt="%s f%s">' % (html.escape(name), html.escape(lg["role"]), cell["frame"])
                    stc = "NOTJUDGED" if cls == "NOTJUDGED" else cell["status"].split()[0]
                    tds.append('<td class="cell %s">%s<div class="cap">f%s <span class="st %s">%s</span><br>'
                               '<span class="mut">%s</span></div></td>' % (
                                   cls, img, cell["frame"], stc, html.escape(cell["status"]), html.escape(cell["why"])))
                rows.append('<tr><th class="cap">%s<br><span class="mut">%s</span></th>%s</tr>' % (
                    html.escape(lg["role"]), html.escape(lg["set"]), "".join(tds)))
            body.append('<div class="sheet" id="%s"><b>%s</b><table class="grid"><tr><th></th>%s</tr>%s</table>'
                        '<div class="nc"><b>Not comparable:</b> %s</div>%s</div>' % (
                            anchor, html.escape(s["title"]), head, "".join(rows), html.escape(s["not_comparable"]),
                            "".join('<div class="nc st NOTJUDGED">%s</div>' % html.escape(c) for c in s.get("capped", []))))
    idx = ['<div class="idx"><b>By test:</b> ' + "".join('<a href="#%s">%s</a>' % (t, html.escape(t)) for t in by_test) + "</div>"]
    if by_char:
        idx.append('<div class="idx"><b>By character:</b> ' + "".join(
            '<a href="#%s">%s (%d)</a>' % (v[0], html.escape(k), len(v)) for k, v in sorted(by_char.items())) + "</div>")
    if by_ticket:
        idx.append('<div class="idx"><b>By ticket:</b> ' + "".join(
            '<a href="#%s">#%s (%d)</a>' % (v[0], html.escape(k), len(v)) for k, v in sorted(by_ticket.items())) + "</div>")
    lists = []
    for key, title in (("no_reference_leg", "No reference leg (listed, not drawn)"), ("no_picture", "No picture: compares legs, judges nothing a proven picture can show (listed, not drawn)"),
                       ("debt", "Not yet declared (the retrofit's debt)")):
        if meta.get(key):
            lists.append("<h2>%s — %d</h2><div class=\"mut\">%s</div>" % (title, len(meta[key]), html.escape(", ".join(meta[key]))))
    builds = "".join("<li>%s: %s</li>" % (html.escape(k), html.escape(v)) for k, v in meta.get("builds", {}).items())
    doc = ('<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
           '<title>Proof Sheets</title><style>%s</style></head><body><h1>Comparative capture sheets</h1>'
           '<div class="mut">commit %s · run %s · each picture proven against what its gate logged (#291)</div>'
           '<ul class="mut">%s</ul>%s%s%s</body></html>') % (
               CSS, html.escape(meta["commit"]), html.escape(meta["date"]), builds, "".join(idx), "".join(body), "".join(lists))
    (out_dir / "index.html").write_text(doc)
    return out_dir / "index.html"


def build_key(rompath, set_):
    r = subprocess.run([sys.executable, str(ROOT / "tools/build_fingerprint.py"), rompath, "--set", set_],
                       capture_output=True, text=True)
    v = r.stdout.strip().splitlines()[-1] if r.stdout.strip() else "?"
    return ("registered: %s" % v) if r.returncode == 0 else ("UNREGISTERED: %s" % v)


# ── commands ────────────────────────────────────────────────────────────────────────────────────────────────────
def cmd_run(a):
    head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    want = subprocess.run(["git", "rev-parse", a.commit + "^{commit}"], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    if not want:
        print("REFUSED: %s is not a commit" % a.commit)
        return 2
    if want != head:
        print("REFUSED: %s is not HEAD (%s) — building another commit's romset is slice S3 (#291)" % (a.commit, head[:8]))
        return 2
    if not os.environ.get("ROMDIR"):
        print("REFUSED: set ROMDIR")
        return 2
    out = Path(a.out or ROOT / "build" / "sheets" / head[:12]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    rows = registry_gates(ROOT / "tests/ci_emulator.tsv")
    meta = {"commit": head, "date": time.strftime("%Y-%m-%d %H:%M"), "gates": [], "no_reference_leg": [], "no_picture": [], "debt": [], "builds": {}}
    declared = []
    for r in select(rows, a.gate, a.char, a.ticket):
        d, err = parse_declaration(ROOT / "tests" / (r[0] + ".sh"))
        if err or d is None:
            meta["debt"].append(r[0])
        elif d["kind"] == "no-reference-leg":
            meta["no_reference_leg"].append(r[0])
        elif d["kind"] == "no-picture":
            meta["no_picture"].append(r[0])
        elif d["kind"] == "legs":
            declared.append(r)
    for r in declared:
        g = r[0]
        sd = out / "gates" / g
        print("== %s: running the gate with SHEET_OUT" % g, flush=True)
        res = run_gate(r, sd, out / ("%s.log" % g))
        print("   %s (exit %d, %ds)" % (res["verdict"], res["rc"], res["seconds"]), flush=True)
        res["tickets"] = sorted(set(re.findall(r"#(\d+)", "\n".join(leading_block(ROOT / "tests" / (g + ".sh"))))))
        if not (sd / "sheet.tsv").exists():
            res["verdict"] += " — the gate wrote no sheet"
            meta["gates"].append(res)
            continue
        print("   capturing and proving", flush=True)
        res["sheets"] = prove_dir(sd, a.jobs)
        n = sum(len(c["cells"]) for s in res["sheets"] for c in s["cols"])
        bad = sum(1 for s in res["sheets"] for c in s["cols"] for x in c["cells"].values() if x["status"] == "NOT THE JUDGED RUN")
        print("   %d sheet(s), %d picture(s), %d NOT THE JUDGED RUN" % (len(res["sheets"]), n, bad), flush=True)
        for s in res["sheets"]:
            for lg in s["legs"]:
                if lg["role"] == "ours":
                    k = "%s on %s" % (lg["set"], lg["rompath"].split(";")[0])
                    if k not in meta["builds"]:
                        meta["builds"][k] = build_key(lg["rompath"], lg["set"])
        meta["gates"].append(res)
    (out / "meta.json").write_text(json.dumps(meta, indent=1))
    p = page(out, meta)
    print("WROTE %s" % p)
    return 0


def cmd_prove(a):
    if not os.environ.get("ROMDIR"):
        print("REFUSED: set ROMDIR")
        return 2
    try:
        sheets = prove_dir(a.dir, a.jobs)
    except ValueError as e:
        print("REFUSED: %s" % e)
        return 2
    for s in sheets:
        for c in s["cols"]:
            for leg, x in c["cells"].items():
                print("%s\t%s\t%s\tf%s\t%s\t%s" % (s["sid"], c["label"], leg, x["frame"], x["status"], x["why"]))
    return 0


def cmd_page(a):
    meta = json.loads((Path(a.dir) / "meta.json").read_text())
    print("WROTE %s" % page(a.dir, meta))
    return 0


def cmd_census(a):
    rows, problems = census(a.tests, a.registry, a.debt)
    for g, c in rows:
        print("%s\t%s" % (c, g))
    for p in problems:
        print("PROBLEM\t%s" % p)
    return 1 if problems else 0


def main(argv):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("commit", nargs="?", default="HEAD")
    r.add_argument("--gate", action="append")
    r.add_argument("--char")
    r.add_argument("--ticket")
    r.add_argument("--jobs", type=int, default=4)
    r.add_argument("--out")
    p = sub.add_parser("prove")
    p.add_argument("dir")
    p.add_argument("--jobs", type=int, default=4)
    g = sub.add_parser("page")
    g.add_argument("dir")
    c = sub.add_parser("census")
    c.add_argument("--tests", default=str(ROOT / "tests"))
    c.add_argument("--registry", default=str(ROOT / "tests/ci_emulator.tsv"))
    c.add_argument("--debt", default=str(ROOT / "tests/expected/sheet_debt.txt"))
    a = ap.parse_args(argv)
    return {"run": cmd_run, "prove": cmd_prove, "page": cmd_page, "census": cmd_census}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
