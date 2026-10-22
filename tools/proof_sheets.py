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

A CONTROL BUILD (#291 S4-A, 14z-206, the maintainer's Q5 "Both as recommended"): a gate whose control leg runs a build
the commit does not make declares it, one line each, in the same leading block:
    # SHEET-BUILD: <VAR> <freeze/tag> <TRACK> — <why the gate needs it>
`run` then checks the tag's commit out in a SECOND clean checkout (build/sheets/<sha>.ctl.tree), builds it there by the
same recipe, refuses unless every track equals that commit's own frozen reference (and TRACK the tag's program key),
passes VAR=<that build's dir> to the gate, and the page labels it "control build, from <tag>, not the commit".

A GATE-BUILT VARIANT (#291, 14z-206, ruled 2026-10-22 "Built in checkout, stated (Recommended)"): a gate whose `ours`
leg runs a variant it builds for itself (test_tenant_select_records' 0x13 image) declares the builder:
    # SHEET-VARIANT: <VAR> tests/lib/<file>.sh <function> <vsavj|vsavjw> — <why>
`run` builds it once in the clean checkout's build/sheet_variants/<function>/ (`. <file>; <function> <work>`, which
sets OUTBASE), passes VAR=<OUTBASE> to the gate, and the page states "gate-built variant, from the commit, no frozen
reference" with its fingerprint. Nothing freezes that fingerprint, so drift is shown, never refused.

SLICE S3 (14z-205): "OURS" IS BUILT FROM THE COMMIT ("Built from the commit", ruled 2026-10-16). `run <commit>` bundles
the commit, clones it into a CLEAN CHECKOUT (never the working tree), builds there the five tracks the commit's own
runner defaults name (tests/run_all_emulator.sh: MERGED DON HUI PYR STOCK) by the commit's reproducibility recipe
(tests/test_m3a_reproducible.sh), and REFUSES the run unless each built track's fingerprint equals the commit's own
frozen reference (that gate's EXPECT_* lines: the anchor sits outside this tool, [VSP-166]). It then runs the commit's
gates, capture scripts and notes from the checkout. A picture of an `ours` leg is shown as NOT THE JUDGED RUN unless
that leg ran on a build made in the checkout's build/ during this run (commit_check). The page states the commit, each
built track's fingerprint, and the emulator binaries (the host's pinned builds: an emulator is not built from the
commit). With `--host pilot|eris` the same run happens on that machine: the bundle and this file are sent, the run is
started there (PILOT: detached; ERIS: held open by the ssh, WSL2 stops a distro with no client), polled with a bounded
ssh, and the page is brought back to build/sheets/<commit>/. The commit's own copy of this tool is not used, so a
commit from before S3 is drawn by this one; a commit from before S1 (no tests/lib/sheet.sh) is refused.

Usage:
    proof_sheets.py run [<commit>] [--gate G]... [--char C] [--ticket N] [--jobs N] [--out DIR] [--tree DIR]
                        [--reuse-tree] [--host pilot|eris [--host-dir D] [--host-romdir D] [--host-timeout S]]
    proof_sheets.py prove <sheet_out dir> [--jobs N]       re-run, photograph and prove one gate's SHEET_OUT
    proof_sheets.py page <out dir>                         re-draw the page from proven sheets
    proof_sheets.py commitcheck <proof.json> <tree>        S3's ours-leg check on a proven sheet (ground truth)
    proof_sheets.py census [--tests DIR] [--registry F] [--debt F]
Env: ROMDIR (required for run/prove), MAME_BIN.
"""
from collections import Counter
import concurrent.futures, glob, html, json, os, re, shutil, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOL_ROOT = ROOT                          # the repository this file sits in; `run` points ROOT at the clean checkout
ROLES = ("vs2", "vsavj", "ours")          # row order on a sheet: native vs2 on top, then vsavj, then ours (#177)
BASES = ("log", "ram", "fields", "file", "event", "none")
DECL = re.compile(r"^#\s*SHEET:\s*(.*)$")
SHEET_BUILD = re.compile(r"^#\s*SHEET-BUILD:\s*(.*)$")
SHEET_VARIANT = re.compile(r"^#\s*SHEET-VARIANT:\s*(.*)$")
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


def parse_sheet_builds(path):
    """-> ([{var, tag, track, why}], [errors]): the gate's `# SHEET-BUILD:` lines (its control builds)."""
    out, errs = [], []
    for l in leading_block(path):
        m = SHEET_BUILD.match(l)
        if not m:
            continue
        parts = DASH.split(m.group(1).strip(), maxsplit=1)
        f = parts[0].split()
        why = parts[1].strip() if len(parts) > 1 else ""
        if len(f) != 3 or not re.match(r"^[A-Z_][A-Z0-9_]*$", f[0]) or not f[1].startswith("freeze/") or f[2] not in TRACKS or not why:
            errs.append("`# SHEET-BUILD:` must read `<VAR> <freeze/tag> <%s> — <why>` (got %r)" % ("|".join(TRACKS), m.group(1)[:80]))
            continue
        out.append({"var": f[0], "tag": f[1], "track": f[2], "why": why})
    return out, errs


def parse_sheet_variants(path):
    """-> ([{var, lib, func, set, why}], [errors]): the gate's `# SHEET-VARIANT:` lines, each a variant the gate builds
    for itself (ruled 2026-10-22, "Built in checkout, stated"): `run` builds it in the clean checkout's build/ with the
    commit's own builder and hands it to the gate through VAR."""
    out, errs = [], []
    for l in leading_block(path):
        m = SHEET_VARIANT.match(l)
        if not m:
            continue
        parts = DASH.split(m.group(1).strip(), maxsplit=1)
        f = parts[0].split()
        why = parts[1].strip() if len(parts) > 1 else ""
        if (len(f) != 4 or not re.match(r"^[A-Z_][A-Z0-9_]*$", f[0]) or not re.match(r"^tests/lib/[A-Za-z0-9_]+\.sh$", f[1])
                or not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", f[2]) or f[3] not in ("vsavj", "vsavjw") or not why):
            errs.append("`# SHEET-VARIANT:` must read `<VAR> tests/lib/<file>.sh <function> <vsavj|vsavjw> — <why>` (got %r)" % m.group(1)[:80])
            continue
        out.append({"var": f[0], "lib": f[1], "func": f[2], "set": f[3], "why": why})
    return out, errs


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


def census(tests, registry, debt, span_debt=None):
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
        for e in parse_verdict_legend(p)[1]:           # #291 S4-C: a gate's own verdict words, well formed
            problems.append("%s: %s" % (g, e))
        rows.append((g, d["kind"]))
    for g in sorted(owed_set - set(gates)):
        problems.append("%s: in the debt list but not an emulator-registry gate — remove it" % g)
    problems += span_census(tests, [g for g, c in rows if c == "legs"], span_debt or ROOT / "tests/expected/sheet_span_debt.txt")
    return rows, problems


SPAN_ROWS = re.compile(r"\bsheet_(span|inputs)\b|[\"']span\\t")
EVENT_OR_FILE = re.compile(r"\bsheet_(tap|file)\b")
FIELDS_BASIS = re.compile(r"[\"']fields[\"']|\\tfields\\t|fields\\t")


def spanned_source(text):
    """A gate's code writes spans or inputs, or proves only by the event basis or its own files (no `fields` moment)."""
    return bool(SPAN_ROWS.search(text) or (EVENT_OR_FILE.search(text) and not FIELDS_BASIS.search(text)))


def span_census(tests, legs_gates, span_debt):
    """#291 S4-D/E: every `legs` gate shows about 9 frames per judged event, or is on the shrink-only span debt list
    (tests/expected/sheet_span_debt.txt, the retrofit's work list). A gate counts as spanned when its code writes span
    or inputs rows, or proves by the event basis (`sheet_tap`: an event moment's window is spanned by default), or
    compares its own golden files (`sheet_file`: a JUDGED FILE has no frames to add)."""
    owed = read_debt(span_debt)
    if owed is None:
        return ["no span debt list at %s" % span_debt]
    out = []
    for g in legs_gates:
        spanned = spanned_source((Path(tests) / (g + ".sh")).read_text(errors="replace"))
        if spanned and g in owed:
            out.append("%s: writes spans but is still on the span debt list — remove it (the list only shrinks)" % g)
        elif not spanned and g not in owed:
            out.append("%s: a `legs` gate with no span, inputs or event moments and not on the span debt list" % g)
    for g in sorted(set(owed) - set(legs_gates)):
        out.append("%s: on the span debt list but not a `legs` gate — remove it" % g)
    return out


# ── the sheet file ──────────────────────────────────────────────────────────────────────────────────────────────
WIDTH = {"sheet": 6, "leg": 11, "moment": 6, "at": 7, "anchors": 2, "tap": 5, "trace": 5, "span": 5, "inputs": 3}
SPAN_N = 9          # #291 S4-D (the maintainer, Q1): about 9 tiles per judged event, "unless it currently has more than 9
                    # tiles already in which case keep the current number" — an explicit frame list is kept whole
INPUTS_MAX = 18     # #291 S4-E (the maintainer, Q2): "at the replay's inputs, up to 18 frames" — "18 per round" (2026-10-21)


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
                           "legs": {}, "moments": {}, "mids": [], "anchors": False, "inputs": None}
            order.append(sid)
            continue
        if sid not in sheets:
            raise ValueError("sheet.tsv:%d: %s row for undeclared sheet %s" % (n, kind, sid))
        s = sheets[sid]
        if kind == "leg":
            if f[3] not in ROLES:
                raise ValueError("sheet.tsv:%d: role %r" % (n, f[3]))
            s["legs"][f[2]] = {"leg": f[2], "role": f[3], "set": f[4], "rompath": abs_rompath(f[5]), "replay": f[6],
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
        elif kind == "inputs":
            if not re.match(r"^\d+$", f[2]) or not 0 < int(f[2]) <= INPUTS_MAX:
                raise ValueError("sheet.tsv:%d: inputs takes 1..%d frames, not %r" % (n, INPUTS_MAX, f[2]))
            s["inputs"] = int(f[2])
        elif kind == "trace":
            if f[2] not in s["legs"]:
                raise ValueError("sheet.tsv:%d: trace row for undeclared leg %s" % (n, f[2]))
            s["legs"][f[2]]["trace"] = {"file": f[3], "spec": parse_trace_spec(f[4], n)}
        elif kind == "span":
            m = s["moments"].get(f[2])
            if m is None or f[3] not in m["at"]:
                raise ValueError("sheet.tsv:%d: span row before the at-row of moment %s leg %s" % (n, f[2], f[3]))
            at = m["at"][f[3]]
            if at["basis"] not in ("log", "fields", "event"):
                raise ValueError("sheet.tsv:%d: a span proves each frame on the moment's basis; basis %r cannot (log, fields or event)" % (n, at["basis"]))
            if at["basis"] == "fields" and not s["legs"][f[3]].get("trace"):
                raise ValueError("sheet.tsv:%d: a fields span needs the leg's trace row first (the gate's per-frame trace proves each frame)" % n)
            m.setdefault("span", {})[f[3]] = span_frames(f[4], at["frame"], n)
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
    for s in sheets.values():          # S4-D: an `event` moment's own window IS its judged event: spanned by default
        for m in s["moments"].values():
            for leg, at in m["at"].items():
                ev = re.match(r"^(.+):(\d+)-(\d+)$", at["expect"]) if at["basis"] == "event" else None
                if ev and leg not in m.get("span", {}):
                    m.setdefault("span", {})[leg] = span_frames("%s-%s" % (ev.group(2), ev.group(3)), at["frame"])
    return [sheets[k] for k in order]


def parse_trace_spec(spec, n=0):
    """A trace row's FIELDS spec, field_trace.lua's `addr:size:name,...` -> {name: "addr:size"} (the at-rows' key form)."""
    out = {}
    for item in spec.split(","):
        m = re.match(r"^\s*([0-9a-fA-F]+):([bwl]):([A-Za-z0-9_.]+)\s*$", item)
        if not m:
            raise ValueError("sheet.tsv:%d: trace spec entry %r is not addr:size:name" % (n, item))
        out[m.group(3)] = "%s:%s" % (m.group(1).lower(), m.group(2))
    return out


def span_frames(spec, keep, n=0):
    """A span row's frames: `lo-hi` -> SPAN_N frames spread evenly across the window, the moment's own frame among
    them; `a,b,c` -> exactly those (an explicit list is kept whole: Q1). Always sorted, unique, `keep` included."""
    m = re.match(r"^(\d+)-(\d+)$", spec)
    if m:
        lo, hi = int(m.group(1)), int(m.group(2))
        if lo > hi:
            raise ValueError("sheet.tsv:%d: span %s is inverted" % (n, spec))
        if hi - lo + 1 <= SPAN_N:
            fr = list(range(lo, hi + 1))
        else:
            fr = sorted({lo + round(i * (hi - lo) / (SPAN_N - 1)) for i in range(SPAN_N)})
            if keep not in fr and lo <= keep <= hi:
                fr[min(range(len(fr)), key=lambda i: abs(fr[i] - keep))] = keep
    elif re.match(r"^\d+(,\d+)*$", spec):
        fr = [int(x) for x in spec.split(",")]
    else:
        raise ValueError("sheet.tsv:%d: span %r is neither lo-hi nor a frame list" % (n, spec))
    return sorted(set(fr) | {keep})


def read_trace(path):
    """field_trace.lua's file -> {frame: {name: value}}."""
    out = {}
    for line in Path(path).read_text(errors="replace").splitlines():
        t = line.split()
        if len(t) >= 2 and t[0] == "F" and t[1].isdigit():
            out[int(t[1])] = {k: int(v) for k, _, v in (kv.partition("=") for kv in t[2:]) if re.match(r"^-?\d+$", v)}
    return out


def abs_rompath(rp):
    """A leg's rom path with each relative element made absolute against ROOT, the tree its gate ran in (gates run
    from it: run_gate's cwd). A capture runs in its own work directory, where a relative element names nothing and MAME
    falls through to the next element: #291 S4-A (14z-206) measured test_gfx_menus' ours leg, recorded as
    `build/m5_stock22/rompath;$ROMDIR` (the registry's %STOCK_RP%), re-run on PRISTINE vsavj from ROMDIR."""
    return ";".join(e if not e.strip() or os.path.isabs(e) else str(ROOT / e) for e in rp.split(";"))


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


def parse_screen(text):
    """tests/lua/screen_state.lua's `R` line body -> {name: int} (m4/m8 are hex, the rest decimal)."""
    out = {}
    for kv in text.split():
        k, _, v = kv.partition("=")
        out[k] = int(v, 16) if k in ("m4", "m8") else int(v)
    return out


MATCH_M8 = (0x40000, 0x60000)     # $FF8008 in a match: fighting, and the frame the next round spawns


def fighters(sc):
    """#291 S4-B: are the fighters on screen in this picture? -> "yes" | "no" | None (no state was read).
    "yes" = a match is on ($FF8004 0x40000, $FF8008 0x40000 or 0x60000) and the OBJ list draws at least one entry
    with a fighter palette (0x01-0x09: tests/lua/screen_state.lua's `fp`). SCORED BEFORE IT WAS TRUSTED (14z-206,
    build/agent206/t291/s4b/, local): chosen on 118 pictures classified by eye, then confirmed with this instrument on
    all 201 of the sample (ten gates of the S3 page re-captured on this Mac, every picture proven): every one of the 104
    showing the fighters read yes, every one of the 89 showing none read no, and 7 of the 8 showing ONE fighter entering
    an otherwise bare stage read no (they go to the labelled strip, never dropped). tests/test_proof_sheets.sh section 6
    holds five pictures of a frozen vanilla run to it."""
    if not sc or "fp" not in sc:
        return None
    return "yes" if sc.get("m4") == 0x40000 and sc.get("m8") in MATCH_M8 and sc["fp"] >= 1 else "no"


# The atlas slot table (docs/game/atlas/character_tables.md), held by tests/test_charid_names.sh; the ids are the same in
# vsavj, vsav2 and vhunt2 (that file's "Variant-slot semantics"), so one map names every leg. The maintainer's names.
NAMES = {0x00: "Bulleta", 0x01: "Demitri", 0x02: "Gallon", 0x03: "Victor", 0x04: "Zabel", 0x05: "Morrigan",
         0x06: "Anakaris", 0x07: "Felicia", 0x08: "Bishamon", 0x09: "Aulbath", 0x0A: "Sasquatch", 0x0B: "random",
         0x0C: "Q-Bee", 0x0D: "Lei-Lei", 0x0E: "Lilith", 0x0F: "Jedah", 0x10: "Phobos", 0x11: "Pyron",
         0x12: "Marionette", 0x13: "Donovan", 0x18: "Oboro"}
WHO_PAIRS = 4                     # above this many pairings a line names each side's characters instead of every pair


def who(sc):
    """Who plays whom, at what speed, in this picture: (P1 id, P2 id, speed level) read from the game's state
    (tests/lua/screen_state.lua's c1/c2/lv: $FF8782, $FF8B82, $FF8116), or None where the fighters are not on screen
    or no state was read. The maintainer, 14z-206: "it would be great if each test / gate had a concise description:
    basically which characters and what setup is tested" — the characters are MEASURED, never written by hand."""
    if fighters(sc) != "yes" or "c1" not in sc:
        return None
    return (sc["c1"], sc["c2"], sc["lv"])


def char_name(i):
    return NAMES.get(i, "id %02x" % i)


def who_text(counts):
    """Counter {(c1, c2, lv): pictures} -> one line: "P1 Donovan vs P2 Demitri, speed level 6"; several pairings each
    with its picture count, most first; above WHO_PAIRS pairings, each side's characters. "" when nothing was read."""
    if not counts:
        return ""
    lv = sorted({k[2] for k in counts})
    speed = "speed level %s" % "/".join(str(v) for v in lv)
    pairs = Counter()
    for (c1, c2, _), n in counts.items():
        pairs[(c1, c2)] += n
    if len(pairs) == 1:
        (c1, c2), = pairs
        return "P1 %s vs P2 %s, %s" % (char_name(c1), char_name(c2), speed)
    if len(pairs) <= WHO_PAIRS:
        return "%s; %s" % ("; ".join("P1 %s vs P2 %s (%d picture%s)" % (char_name(a), char_name(b), n, "" if n == 1 else "s")
                                     for (a, b), n in sorted(pairs.items(), key=lambda kv: (-kv[1], kv[0]))), speed)
    side = lambda k: ", ".join(char_name(i) for i in sorted({p[k] for p in pairs}))
    return "%d pairings: P1 %s; P2 %s; %s" % (len(pairs), side(0), side(1), speed)


def sheet_who(s):
    """{leg: Counter} over every picture of a sheet (its moments, strips and timeline) that shows the fighters."""
    out = {}
    for c in s["cols"]:
        xs = list(c["cells"].items()) + [(leg, x) for leg, ys in c.get("strip", {}).items() for x in ys if not x.get("moment")]
        for leg, x in xs:
            k = x.get("who")
            if k:
                out.setdefault(leg, Counter())[tuple(k)] += 1
    return out


def legs_who(legs, counts):
    """[(role label, text)]: one line when every leg reads the same, else one per leg."""
    texts = [(lg["role"] + " (" + lg["set"] + ")", who_text(counts.get(lg["leg"], Counter()))) for lg in legs]
    if texts and all(x == texts[0][1] for _, x in texts):
        return [("every leg", texts[0][1])] if texts[0][1] else []
    return [(r, x or "no picture shows the fighters") for r, x in texts]


# ── capture and prove ───────────────────────────────────────────────────────────────────────────────────────────
def leg_frames(s, leg):
    """Every frame the leg is photographed at: its moments' frames (a `file` basis is the gate's own picture) and, since
    #291 S4-D, every frame of their spans."""
    fr = {a["frame"] for m in s["moments"].values() for l, a in m["at"].items() if l == leg and a["basis"] != "file"}
    fr |= {f for m in s["moments"].values() for f in m.get("span", {}).get(leg, [])}
    return sorted(fr)


def capture(sheet_dir, s, leg, work, frames=None, tag=None):
    """Run one leg under sheet_capture.lua; -> {"C": {frame: hex}, "V": {frame: {spec: v}}, "A": [(frame, label)],
    "S": {frame: png}, "R": {frame: screen state}, "error": str|None}. With `frames` (the S4-E inputs pass) only those
    frames are photographed, without anchors, in a work dir of their own (`tag`)."""
    lg = s["legs"][leg]
    anchors = s["anchors"] and frames is None
    frames = leg_frames(s, leg) if frames is None else sorted(frames)
    specs = sorted({k for m in s["moments"].values() for l, a in m["at"].items()
                    if l == leg and a["basis"] == "fields" for k in parse_fields(a["expect"])})
    res = {"C": {}, "V": {}, "A": [], "S": {}, "R": {}, "T": None, "error": None, "capped": None}
    if not frames and not anchors:
        return res
    w = Path(work) / ("%s.%s%s" % (s["sid"], leg, "." + tag if tag else ""))
    shutil.rmtree(w, ignore_errors=True)
    w.mkdir(parents=True)
    if lg.get("tap"):
        return capture_tap(sheet_dir, lg, frames, w, res)
    env = dict(os.environ, MAME_SANDBOX=str(w / "sb"), MAME_ROMPATH=lg["rompath"],
               REPLAY=str(Path(sheet_dir) / lg["replay"]), POKES=lg["pokes"], MASK_RANGES=lg["mask"],
               SNAP_FRAMES=",".join(map(str, frames)), FIELDS=",".join(specs), CAPTURE_OUT=str(w / "cap.txt"),
               FRAMES=str(lg["frames"] if anchors else max(frames) + 1), ANCHORS="1" if anchors else "")
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
        elif t[0] == "R":
            res["R"][int(t[1])] = parse_screen(t[2])
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
        if len(t) > 2 and t[0] == "R":
            res["R"][int(t[1])] = parse_screen(line.split(" ", 2)[2])
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


def prove_span_frame(fr, at, lg, cap, sheet_dir, traces):
    """One frame of a moment's span, proven on the moment's own basis (#291 S4-D): `log` at that frame of the leg's
    log; `fields` the moment's compared fields read from the gate's per-frame trace at that frame; `event` the gate's
    tap lines over the moment's window widened to reach the frame. -> (status, why)."""
    if at["basis"] == "log":
        return prove({"frame": fr, "basis": "log", "expect": "-"}, lg, cap, sheet_dir)
    if at["basis"] == "fields":
        tr = traces.get(lg["leg"])
        if tr is None:
            tr = traces[lg["leg"]] = read_trace(Path(sheet_dir) / lg["trace"]["file"])
        row = tr.get(fr)
        if row is None:
            return "UNPROVEN", "the gate's trace has no f%d" % fr
        by_key = {v: k for k, v in lg["trace"]["spec"].items()}
        keys = list(parse_fields(at["expect"]))
        missing = [k for k in keys if k not in by_key or by_key[k] not in row]
        if missing:
            return "UNPROVEN", "the gate's trace does not carry %s" % ", ".join(missing[:3])
        return prove({"frame": fr, "basis": "fields", "expect": ",".join("%s=%d" % (k, row[by_key[k]]) for k in keys)}, lg, cap, sheet_dir)
    m = re.match(r"^(.+):(\d+)-(\d+)$", at["expect"])
    if not m:
        return "NOT THE JUDGED RUN", "an event expectation is <log>:<lo>-<hi>, not %r" % at["expect"]
    lo, hi = min(int(m.group(2)), fr), max(int(m.group(3)), fr)
    return prove({"frame": fr, "basis": "event", "expect": "%s:%d-%d" % (m.group(1), lo, hi)}, lg, cap, sheet_dir)


def replay_inputs(path):
    """A replay's inputs (replay.lua grammar) -> (onsets, held): the frames at which a range starts holding an input,
    and every frame some input is held."""
    on, held = set(), set()
    for line in Path(path).read_text(errors="replace").splitlines():
        body = line.split("#", 1)[0].split()
        if len(body) >= 2:
            m = re.match(r"^(\d+)(?:-(\d+))?$", body[0])
            if m and any(re.match(r"^(p1|p2|sys)=\S+$", x) for x in body[1:]):
                a = int(m.group(1)); b = int(m.group(2) or a)
                on.add(a); held.update(range(a, b + 1))
    return sorted(on), sorted(held)


def spread(frames, n):
    """n of `frames` spread evenly (all of them when there are no more than n)."""
    if len(frames) <= n:
        return list(frames)
    return [frames[round(i * (len(frames) - 1) / (n - 1))] for i in range(n)] if n > 1 else frames[:1]


def rounds(anchors, last):
    """The in-round windows of a leg from its anchors: each `round start` to the next anchor that ends the fight (a
    down settling or any other round-phase change), or the leg's last frame."""
    out, open_at = [], None
    for fr, label in anchors:
        if label == "round start":
            if open_at is not None:
                out.append((open_at, fr - 1))
            open_at = fr
        elif open_at is not None and (label.startswith("down settles") or label.startswith("round phase")):
            out.append((open_at, fr))
            open_at = None
    if open_at is not None:
        out.append((open_at, last))
    return out


def input_picks(s, ref, cap, sheet_dir):
    """#291 S4-E (Q2, "at the replay's inputs, up to 18 frames"; the maintainer 2026-10-21: "18 per round"): in EACH
    round of the REFERENCE leg (its anchors), up to s["inputs"] frames where its replay holds an input: the frames
    where an input STARTS first, spread evenly when there are more; when there are fewer, the rest spread over the
    frames an input is HELD (a replay of long held ranges, such as Felicia's wall jump, has few onsets).
    -> [(frame, label)]."""
    lg = s["legs"][ref]
    onsets, held = replay_inputs(Path(sheet_dir) / lg["replay"])
    n, labels = s["inputs"], []
    for k, (a, b) in enumerate(rounds(cap["A"], lg["frames"])):
        on = spread([f for f in onsets if a < f <= b], n)
        if len(on) < n:
            taken = set(on)
            on += spread([f for f in held if a < f <= b and f not in taken], n - len(on))
        labels += [(f, "input at f%d (round %d)" % (f, k + 1)) for f in sorted(set(on))]
    return labels


def cell_of(st, why, fr, pic, cap):
    return {"frame": fr, "status": st, "why": why, "pic": pic, "screen": cap["R"].get(fr) if fr is not None else None}


def prove_dir(sheet_dir, jobs=4):
    """Capture and prove every sheet of one gate's SHEET_OUT; writes proof.json beside it and returns it."""
    sheet_dir = Path(sheet_dir).resolve()  # each capture runs in its own work dir: a relative path would not resolve there
    sheets = read_sheet(sheet_dir)
    work = sheet_dir / "capture"
    caps = {}

    def run_all(tasks):
        with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, jobs)) as ex:
            futs = {ex.submit(fn, *args): key for key, fn, args in tasks}
            for fu in concurrent.futures.as_completed(futs):
                caps[futs[fu]] = fu.result()
    run_all([((s["sid"], leg), capture, (sheet_dir, s, leg, work)) for s in sheets for leg in s["legs"]])
    picks = {}                                       # S4-E: the inputs pass needs the first pass's anchors
    for s in sheets:
        if s["inputs"] and s["anchors"]:
            ref = sorted(s["legs"].values(), key=lambda l: (ROLES.index(l["role"]), l["leg"]))[0]["leg"]
            picks[s["sid"]] = input_picks(s, ref, caps[(s["sid"], ref)], sheet_dir)
    run_all([((s["sid"], leg, "inputs"), capture, (sheet_dir, s, leg, work, [f for f, _ in picks[s["sid"]]], "inputs"))
             for s in sheets if picks.get(s["sid"]) for leg in s["legs"]])
    out = []
    for s in sheets:
        legs = sorted(s["legs"].values(), key=lambda l: (ROLES.index(l["role"]), l["leg"]))
        cols, traces = [], {}
        for mid in s["mids"]:
            m = s["moments"][mid]
            cells, strip = {}, {}
            for lg in legs:
                at = m["at"].get(lg["leg"])
                if not at:
                    continue
                cap = caps[(s["sid"], lg["leg"])]
                st, why = ("NOT THE JUDGED RUN", cap["error"]) if cap["error"] and at["basis"] != "file" else prove(at, lg, cap, sheet_dir)
                pic = str(sheet_dir / at["expect"]) if at["basis"] == "file" else cap["S"].get(at["frame"])
                cells[lg["leg"]] = cell_of(st, why, at["frame"], pic, cap)
                for fr in m.get("span", {}).get(lg["leg"], []):
                    if fr == at["frame"]:
                        x = dict(cells[lg["leg"]], moment=True)
                    else:
                        st2, why2 = ("NOT THE JUDGED RUN", cap["error"]) if cap["error"] else prove_span_frame(fr, at, lg, cap, sheet_dir, traces)
                        x = dict(cell_of(st2, why2, fr, cap["S"].get(fr), cap), moment=False)
                    strip.setdefault(lg["leg"], []).append(x)
            col = {"label": m["label"], "verdict": m["verdict"], "values": m["values"], "cells": cells}
            if strip:
                col["strip"] = strip
            cols.append(col)
        if s["anchors"]:
            ref = legs[0]["leg"]
            for k, (fr, label) in enumerate(caps[(s["sid"], ref)]["A"]):
                cells = {}
                for lg in legs:
                    cap = caps[(s["sid"], lg["leg"])]
                    if k >= len(cap["A"]):
                        cells[lg["leg"]] = {"frame": None, "status": "NOT THE JUDGED RUN", "why": "this leg has no anchor %d" % (k + 1), "pic": None, "screen": None}
                        continue
                    afr, alabel = cap["A"][k]
                    st, why = prove({"frame": afr, "basis": "log", "expect": "-"}, lg, cap, sheet_dir)
                    if (afr, alabel) != (fr, label):
                        why += "; this leg's anchor %d is %s at f%d" % (k + 1, alabel, afr)
                    cells[lg["leg"]] = cell_of(st, why, afr, cap["S"].get(afr), cap)
                cols.append({"label": "anchor: " + label, "verdict": "-", "values": "-", "cells": cells})
        for fr, label in picks.get(s["sid"], []):
            cells = {}
            for lg in legs:
                cap = caps.get((s["sid"], lg["leg"], "inputs"))
                if cap is None or cap["error"]:
                    cells[lg["leg"]] = {"frame": fr, "status": "NOT THE JUDGED RUN", "why": (cap or {}).get("error") or "no inputs pass", "pic": None, "screen": None}
                    continue
                st, why = prove({"frame": fr, "basis": "log", "expect": "-"}, lg, cap, sheet_dir)
                cells[lg["leg"]] = cell_of(st, why, fr, cap["S"].get(fr), cap)
            cols.append({"label": label, "verdict": "-", "values": "-", "cells": cells, "input": True})
        capped = [("%s: %s" % (lg["leg"], caps[(s["sid"], lg["leg"])]["capped"])) for lg in legs
                  if caps[(s["sid"], lg["leg"])]["capped"]]
        for c in cols:                                # S4-B: whether the fighters are on screen, read from the game's state
            for x in all_cells(c):
                x["fighters"] = fighters(x.get("screen"))
                x["who"] = who(x.get("screen"))
            for xs in c.get("strip", {}).values():
                for x in xs:
                    x["fighters"] = fighters(x.get("screen"))
                    x["who"] = who(x.get("screen"))
        out.append({"sid": s["sid"], "title": s["title"], "chars": s["chars"], "tickets": s["tickets"],
                    "not_comparable": s["not_comparable"], "capped": capped,
                    "legs": [{"leg": l["leg"], "role": l["role"], "set": l["set"], "rompath": l["rompath"]} for l in legs],
                    "cols": cols})
    (sheet_dir / "proof.json").write_text(json.dumps(out, indent=1))
    return out


def who_cell(x):
    """The prove listing's who column: "<P1 id>/<P2 id>/<speed level>" in hex/hex/decimal, or "-"."""
    k = x.get("who")
    return "%02x/%02x/%d" % tuple(k) if k else "-"


def all_cells(col):
    """Every picture cell of a column: the moment's own cells and, since S4-D, its strips' other frames."""
    out = list(col["cells"].values())
    for leg, xs in col.get("strip", {}).items():
        out += [x for x in xs if not x.get("moment")]
    return out


# ── running the gates ───────────────────────────────────────────────────────────────────────────────────────────
def runner_defaults(root=None):
    txt = (Path(root or ROOT) / "tests/run_all_emulator.sh").read_text()
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


def run_gate(row, sheet_dir, log, extra_env=None):
    gate, args = row[0], row[4] if len(row) > 4 else "-"
    tmo = int(row[6]) if len(row) > 6 and row[6].strip().isdigit() else 5400
    env, pos = dict(os.environ, SHEET_OUT=str(sheet_dir), **(extra_env or {})), []
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
.who{margin:2px 0;max-width:1100px} .who p{display:inline;margin:0}
.strip .cell img{width:128px} .strip .cap{max-width:128px} .MOMENT img{border:3px solid var(--fg)}
.mblock{margin:8px 0 12px} .mh{margin:4px 0} .legend,.nof{margin:8px 0} .lg dt{font-weight:600;margin-top:4px} .lg dd{margin:0 0 0 16px}
h3{font-size:14px;margin:12px 0 4px}
"""


REPO_URL = "https://github.com/DefinitelyFrenchName/VampireSaved/issues/"


def sheet_notes(path=None):
    """docs/project/sheet_notes.md -> {gate: text}: each `## <gate>` section's body (14z-205, #291). Read from ROOT at
    call time: under `run` that is the commit's checkout, so the notes are the commit's."""
    path = path or ROOT / "docs/project/sheet_notes.md"
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
        elif cur and not line.startswith(SETUP):
            notes[cur].append(line)
    return {g: "\n".join(t).strip() for g, t in notes.items()}


SETUP = "Setup: "


def sheet_setups(path=None):
    """docs/project/sheet_notes.md -> {gate: its one `Setup: ` line} — the setup a state read cannot name (where, what
    is compared, what the rig does), written per gate; the characters are measured instead (who())."""
    path = path or ROOT / "docs/project/sheet_notes.md"
    out, cur = {}, None
    if not Path(path).exists():
        return out
    for line in Path(path).read_text().splitlines():
        m = re.match(r"^## +`?([A-Za-z0-9_]+)`?\s*$", line)
        if m:
            cur = m.group(1)
        elif line.startswith("#"):
            cur = None
        elif cur and line.startswith(SETUP) and cur not in out:
            out[cur] = line[len(SETUP):].strip()
    return out


def gate_who(g):
    """{leg role (set): Counter} over every sheet of a gate, legs matched by role and set."""
    out, legs = {}, {}
    for s in g.get("sheets", []):
        per = sheet_who(s)
        for lg in s["legs"]:
            key = lg["role"] + " (" + lg["set"] + ")"
            legs.setdefault(key, {"leg": key, "role": lg["role"], "set": lg["set"]})
            out.setdefault(key, Counter()).update(per.get(lg["leg"], Counter()))
    return [dict(v, leg=k) for k, v in legs.items()], out


def gate_head(gid, g, setups):
    """The top of a gate's page: its setup line (written) and who plays whom on each leg (read)."""
    out = []
    if gid in setups:
        out.append('<div class="who"><b>Setup:</b> %s</div>' % note_html(setups[gid]))
    legs, counts = gate_who(g)
    for r, x in legs_who([dict(lg, role=lg["role"], set=lg["set"]) for lg in legs], counts):
        out.append('<div class="who"><b>Characters, %s:</b> %s <span class="mut">(read from the game at the pictures)</span></div>'
                   % (html.escape(r), html.escape(x)))
    return "".join(out)


def gate_line(gid, g, setups):
    """The index's "what it tests" cell: the setup line, then the characters (every leg's, when they agree)."""
    legs, counts = gate_who(g)
    lw = legs_who(legs, counts)
    chars = "; ".join(x if r == "every leg" else "%s: %s" % (r, x) for r, x in lw)
    return "%s%s" % (note_html(setups[gid]) if gid in setups else "", ('<br><span class="mut">%s</span>' % html.escape(chars)) if chars else "")


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


STATUS_LEGEND = [
    ("PROVEN", "the re-run's state at this frame equals what the gate logged there: its per-frame work-RAM checksum "
               "log, a checksum, or the RAM fields it compared — this picture is of the run the gate judged"),
    ("EVENT-PROVEN", "the re-run, under the gate's own tap instrument, logged exactly the event lines the gate logged in "
                     "the window around this frame; weaker than PROVEN: work RAM outside the tapped addresses is not proven"),
    ("JUDGED FILE", "the picture the gate itself compared (a frozen golden), shown as it is"),
    ("UNPROVEN", "the gate logged nothing that can prove this picture; shown, never claimed"),
    ("NOT THE JUDGED RUN", "the re-run differs from what the gate judged at this frame (or ran on a build that is not "
                           "the commit's): the picture is NOT evidence; red dashed border"),
]
ROLE_LEGEND = [
    ("vs2", "native Vampire Savior 2 (vsav2), where the ported characters come from"),
    ("vsavj", "vanilla Vampire Savior, Japan 970519 (vsavj), the game this romset extends"),
    ("ours", "the build under test, made from the commit (the role row names its set and rom path)"),
]
TERM_LEGEND = [
    ("f<N>", "a frame number: frames since power-on, 60 per second"),
    ("moment", "one thing the gate judged (a column); its verdict is printed under its label"),
    ("strip", "about 9 frames across a judged event, from its start to its recovery (#291 S4-D); the judged frame "
              "itself has a thick border; every frame is proven on the moment's own basis"),
    ("anchor: …", "a sync point found by the capture: round start, a down settling, the next round spawning, a "
                  "round-phase change"),
    ("input at f<N> (round k)", "a frame where the replay starts holding an input inside round k (#291 S4-E: up to 18 "
                                "in each round)"),
    ("fighters on screen", "read from the game's state at that frame, not from the picture (#291 S4-B): a match is on "
                           "and the sprite list draws a fighter's palette; scored against pictures classed by eye; a "
                           "judged frame where no leg shows a fighter is moved to the labelled strip under its sheet, "
                           "never dropped"),
    ("Judged frames without fighters", "frames the gate judged where no fighter is on screen (the round-end fade, the "
                                       "stage before the drop-in, select/VS/continue screens, wipes); the maintainer's "
                                       "Q3: kept, in a separate strip"),
    ("Not comparable", "what differs between the legs by design, so a difference there is not a finding"),
]
VERDICT_LEGEND = [
    ("IDENTICAL / IDENT / SAME", "the legs' compared values are equal at this moment"),
    ("DIFF / DIFFER", "the legs' compared values differ at this moment; whether that is expected is the gate's verdict "
                      "(a ruled difference, or a finding)"),
    ("PASS / FAIL", "the gate's own check of this moment passed / failed"),
    ("as frozen / as expected / as measured / as ruled", "equal to the gate's frozen expectation file, expected value, "
                                                         "earlier measurement, or the maintainer's ruling"),
    ("-", "a frame shown for context (an anchor or an input frame), not itself judged"),
]
NOTATION_LEGEND = [
    ("1-9", "joystick directions, numpad layout for a fighter facing right: 6 forward, 4 back, 2 down, 8 up, 3 down-forward"),
    ("LP MP HP / LK MK HK", "light, medium, heavy punch / kick; P or K alone = any strength"),
    ("PP / KK / PPP", "two / three punches pressed together; [..] a button combination held together"),
    ("j.", "in the air (jumping): j.66 is an air dash"),
    ("~", "followed by"),
    ("ES / EX", "an enhanced special (spends a stock) / the EX version of a special"),
    ("DF", "Dark Force (each character's timed power-up mode)"),
    ("GC", "guard cancel"),
    ("P1 / P2", "player 1 (left start) / player 2"),
]
COMMON_TAGS = {"IDENTICAL", "IDENT", "SAME", "DIFF", "DIFFER", "PASS", "FAIL", "SKIP",     # the verdict legend
               "LP", "MP", "HP", "LK", "MK", "HK", "PP", "KK", "PPP", "KKK", "ES", "EX", "DF", "GC"}   # the notation legend
TAG = re.compile(r"\b[A-Z][A-Z0-9]+(?:-[A-Z0-9]+)*\b")
SHEET_VERDICTS = re.compile(r"^#\s*SHEET-VERDICTS:\s*(.*)$")
PAGE_TILES = 400        # #291 S4-F: a gate page is split by sheet above this many pictures (~11 MB at S3's 27.6 KB each)


def parse_verdict_legend(path):
    """A gate's `# SHEET-VERDICTS: WORD = meaning; WORD = meaning` lines -> ({word: meaning}, [errors])."""
    out, errs = {}, []
    if not path or not Path(path).exists():
        return out, errs
    for l in leading_block(path):
        m = SHEET_VERDICTS.match(l)
        if not m:
            continue
        for item in m.group(1).split(";"):
            k, eq, v = item.partition("=")
            if not eq or not k.strip() or not v.strip():
                errs.append("`# SHEET-VERDICTS:` entry %r is not WORD = meaning" % item.strip()[:60])
                continue
            out[k.strip()] = v.strip()
    return out, errs


def undefined_tags(verdict, gate_words):
    """The tags of a verdict string the legend does not define: every upper-case word (IDENTICAL, NO-MATCH, NOT-IN-DF)
    must be a common verdict word or one the gate declares (`# SHEET-VERDICTS:`); prose (lower case) is read as prose."""
    words = set(COMMON_TAGS) | {w for k in gate_words for w in TAG.findall(k)}
    return sorted({w for w in TAG.findall(verdict or "") if w not in words and not re.match(r"^(F|P)\d+$", w)})


def legend_html(gate_words=None):
    def dl(title, items):
        return "<h3>%s</h3><dl class=\"lg\">%s</dl>" % (html.escape(title), "".join(
            "<dt>%s</dt><dd>%s</dd>" % (html.escape(k), html.escape(v)) for k, v in items))
    out = dl("Proof status (under each picture)", STATUS_LEGEND) + dl("Rows: the legs", ROLE_LEGEND) + \
        dl("Terms", TERM_LEGEND) + dl("Verdict words used by every gate", VERDICT_LEGEND) + \
        dl("Move notation in labels", NOTATION_LEGEND)
    for g, words in sorted((gate_words or {}).items()):
        if words:
            out += dl("Verdict words of %s" % g, sorted(words.items()))
    return '<details class="legend" open><summary><b>Legend — every tag on these pages</b></summary>%s</details>' % out


def cell_html(gid, sid, lg, cell, name, pics, big=False):
    """One picture with its frame and status. The picture is MOVED into pics/ (#291 S4-F: one copy, not two)."""
    img = ""
    ext = os.path.splitext(cell["pic"] or "")[1].lower() or ".png"
    name = name + ext
    if cell["pic"] and (os.path.exists(cell["pic"]) or (pics / name).exists()):
        if os.path.exists(cell["pic"]) and not (pics / name).exists():
            shutil.move(cell["pic"], pics / name)
        if ext in (".wav", ".ogg", ".mp3"):
            img = '<audio controls preload="none" src="../pics/%s"></audio>' % html.escape(name)
        else:
            img = '<a href="../pics/%s"><img loading="lazy" src="../pics/%s" alt="%s f%s"></a>' % (
                html.escape(name), html.escape(name), html.escape(lg["role"]), cell["frame"])
    cls = "NOTJUDGED" if cell["status"] == "NOT THE JUDGED RUN" else "PROVEN"
    stc = "NOTJUDGED" if cls == "NOTJUDGED" else cell["status"].split()[0]
    fx = {"yes": "", "no": " · no fighter on screen", None: ""}.get(cell.get("fighters"), "")
    return '<td class="cell %s%s">%s<div class="cap">f%s <span class="st %s">%s</span>%s<br><span class="mut">%s</span></div></td>' % (
        cls, " MOMENT" if big else "", img, cell["frame"], stc, html.escape(cell["status"]), html.escape(fx), html.escape(cell["why"]))


def no_fighter(cells):
    """A column (or a strip frame) goes to the no-fighter strip when every leg's picture is read as showing none."""
    vals = [x.get("fighters") for x in cells if x]
    return bool(vals) and all(v == "no" for v in vals)


def sheet_html(gid, s, pics):
    """One sheet: the moments with strips as blocks (legs x frames), the other columns as a timeline (legs x columns),
    and under it the judged frames without fighters (Q3). -> (html, picture count)."""
    anchor = "%s--%s" % (gid, s["sid"])
    s["cols"] = sorted(s["cols"], key=lambda c: min([x["frame"] for x in c["cells"].values() if x["frame"] is not None] or [0]))
    blocks, timeline, nofight, n = [], [], [], 0
    for k, c in enumerate(s["cols"]):
        head = '<div class="mh"><b>%s</b> <span class="mut">%s</span></div>' % (html.escape(c["label"]), html.escape(c["verdict"]))
        if c.get("strip"):
            frames = sorted({x["frame"] for xs in c["strip"].values() for x in xs})
            keep = [f for f in frames if not no_fighter([next((x for x in xs if x["frame"] == f), None) for xs in c["strip"].values()])]
            drop = [f for f in frames if f not in keep]
            rows = []
            for lg in s["legs"]:
                xs = {x["frame"]: x for x in c["strip"].get(lg["leg"], [])}
                tds = []
                for f in keep:
                    x = xs.get(f)
                    if x:
                        n += 1
                        tds.append(cell_html(gid, s["sid"], lg, x, "%s.%s.%s.%d.f%d" % (gid, s["sid"], lg["leg"], k, f), pics, x.get("moment")))
                    else:
                        tds.append("<td></td>")
                rows.append('<tr><th class="cap">%s<br><span class="mut">%s</span></th>%s</tr>' % (
                    html.escape(lg["role"]), html.escape(lg["set"]), "".join(tds)))
            blocks.append('<div class="mblock">%s<table class="grid strip">%s</table></div>' % (head, "".join(rows)))
            for f in drop:
                for lg in s["legs"]:
                    x = next((x for x in c["strip"].get(lg["leg"], []) if x["frame"] == f), None)
                    if x:
                        n += 1
                        nofight.append((c["label"], lg, cell_html(gid, s["sid"], lg, x, "%s.%s.%s.%d.f%d" % (gid, s["sid"], lg["leg"], k, f), pics)))
            continue
        target = nofight if no_fighter(list(c["cells"].values())) else None
        cells = []
        for lg in s["legs"]:
            x = c["cells"].get(lg["leg"])
            if x:
                n += 1
                h = cell_html(gid, s["sid"], lg, x, "%s.%s.%s.%d" % (gid, s["sid"], lg["leg"], k), pics)
                if target is not None:
                    nofight.append((c["label"], lg, h))
                cells.append((lg, h))
        if target is None:
            timeline.append((c, dict((lg["leg"], h) for lg, h in cells)))
    out = ['<div class="sheet" id="%s"><b>%s</b>' % (anchor, html.escape(s["title"]))]
    out += ['<div class="who"><b>%s:</b> %s</div>' % (html.escape(r), html.escape(x)) for r, x in legs_who(s["legs"], sheet_who(s))]
    out += blocks
    if timeline:
        head = "".join('<th class="cap">%s<br><span class="mut">%s</span></th>' % (html.escape(c["label"]), html.escape(c["verdict"])) for c, _ in timeline)
        rows = "".join('<tr><th class="cap">%s<br><span class="mut">%s</span></th>%s</tr>' % (
            html.escape(lg["role"]), html.escape(lg["set"]), "".join(hs.get(lg["leg"], "<td></td>") for _, hs in timeline)) for lg in s["legs"])
        out.append('<table class="grid"><tr><th></th>%s</tr>%s</table>' % (head, rows))
    out.append('<div class="nc"><b>Not comparable:</b> %s</div>' % html.escape(s["not_comparable"]))
    out += ['<div class="nc st NOTJUDGED">%s</div>' % html.escape(c) for c in s.get("capped", [])]
    if nofight:
        out.append('<details class="nof"><summary><b>Judged frames without fighters</b> — %d picture(s): the gate judged them; '
                   'no fighter is on screen (see the legend)</summary><table class="grid"><tr>%s</tr><tr>%s</tr></table></details>' % (
                       len(nofight), "".join('<th class="cap">%s<br><span class="mut">%s</span></th>' % (html.escape(l), html.escape(lg["role"])) for l, lg, _ in nofight),
                       "".join(h for _, _, h in nofight)))
    out.append("</div>")
    return "".join(out), n


def page_doc(title, meta, body, css_extra=""):
    return ('<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            '<title>%s</title><style>%s%s</style></head><body>%s</body></html>') % (html.escape(title), CSS, css_extra, body)


def page(out_dir, meta):
    """#291 S4-F: index.html (the provenance, the legend, the indexes, the lists) and one page per gate under g/, split
    by sheet above PAGE_TILES pictures; pictures load lazily from pics/."""
    out_dir = Path(out_dir)
    pics = out_dir / "pics"
    pics.mkdir(exist_ok=True)
    gdir = out_dir / "g"
    gdir.mkdir(exist_ok=True)
    by_char, by_ticket, by_test, empty, undefined, gate_words = {}, {}, [], [], [], {}
    notes, setups = sheet_notes(), sheet_setups()
    for g in meta["gates"]:
        gid = g["gate"]
        words, errs = parse_verdict_legend(ROOT / "tests" / (gid + ".sh"))
        gate_words[gid] = words
        for e in errs:
            undefined.append("%s: %s" % (gid, e))
        parts, cur, cur_n = [], [], 0
        for s in g.get("sheets", []):
            h, n = sheet_html(gid, s, pics)
            for c in s["cols"]:
                for w in undefined_tags(c["verdict"], words):
                    u = "%s: verdict word %s (first in %r) is defined neither in the common legend nor in the gate's `# SHEET-VERDICTS:`" % (gid, w, c["verdict"][:60])
                    if not any(x.startswith("%s: verdict word %s " % (gid, w)) for x in undefined):
                        undefined.append(u)
            if all(x.get("fighters") == "no" for c in s["cols"] for x in all_cells(c)) and any(all_cells(c) for c in s["cols"]):
                empty.append("%s / %s" % (gid, s["sid"]))
            if cur and cur_n + n > PAGE_TILES:
                parts.append(cur); cur, cur_n = [], 0
            cur.append((s, h)); cur_n += n
        if cur:
            parts.append(cur)
        files = ["%s.html" % gid] + ["%s.%d.html" % (gid, i + 1) for i in range(1, len(parts))]
        by_test.append((gid, files[0], g, len(parts)))
        for i, part in enumerate(parts or [[]]):
            nav = " · ".join(('<a href="%s">part %d</a>' % (f, j + 1)) if j != i else "part %d" % (j + 1) for j, f in enumerate(files)) if len(parts) > 1 else ""
            body = ['<div class="mut"><a href="../index.html">index and legend</a> %s</div>' % (("· " + nav) if nav else "")]
            body.append('<h1 id="%s">%s</h1><div class="mut">gate verdict: %s (%ss)</div>' % (gid, html.escape(gid), html.escape(g["verdict"]), g["seconds"]))
            for cb in g.get("control_builds", []):
                body.append('<div class="nc"><b>Control build:</b> %s</div>' % html.escape(cb))
            for vb in g.get("variant_builds", []):
                body.append('<div class="nc"><b>Gate-built variant:</b> %s</div>' % html.escape(vb))
            body.append(gate_head(gid, g, setups))
            if gid in notes:
                body.append('<div class="note">%s</div>' % note_html(notes[gid]))
            if words:
                body.append(legend_html({gid: words}).replace(" open>", ">"))
            for s, h in part:
                anchor = "%s--%s" % (gid, s["sid"])
                for c in s["chars"]:
                    by_char.setdefault(c, []).append("g/%s#%s" % (files[i], anchor))
                for tk in s["tickets"] + g.get("tickets", []):
                    by_ticket.setdefault(tk.lstrip("#"), []).append("g/%s#%s" % (files[i], anchor))
                body.append(h)
            (gdir / files[i]).write_text(page_doc("%s — Proof Sheets" % gid, meta, "".join(body)))
    idx = ['<div class="idx"><b>By test:</b> ' + "".join('<span class="it"><a href="g/%s">%s</a>%s</span> ' % (f, html.escape(t), (" (%d parts)" % k) if k > 1 else "")
                                                       for t, f, _, k in by_test) + "</div>"]
    if by_char:
        idx.append('<div class="idx"><b>By character:</b> ' + "".join(
            '<a href="%s">%s (%d)</a>' % (v[0], html.escape(k), len(v)) for k, v in sorted(by_char.items())) + "</div>")
    if by_ticket:
        idx.append('<div class="idx"><b>By ticket:</b> ' + "".join(
            '<a href="%s">#%s (%d)</a>' % (v[0], html.escape(k), len(v)) for k, v in sorted(by_ticket.items())) + "</div>")
    verdicts = '<tr><th>gate</th><th>what it tests</th><th>verdict</th><th></th></tr>' + "".join(
        '<tr><td><a href="g/%s">%s</a></td><td>%s</td><td>%s</td><td>%ss</td></tr>' % (
            f, html.escape(t), gate_line(t, g, setups), html.escape(g["verdict"]), g["seconds"]) for t, f, g, _ in by_test)
    top, rest = [], []
    if undefined:
        top.append('<h2 class="st NOTJUDGED">Undefined tags — %d</h2><ul>%s</ul>' % (len(undefined), "".join("<li>%s</li>" % html.escape(u) for u in undefined)))
    if empty:
        top.append('<h2>Sheets where no picture shows the fighters — %d</h2><div class="mut">%s</div>' % (len(empty), html.escape(", ".join(empty))))
    for key, title in (("no_reference_leg", "No reference leg (listed, not drawn)"), ("no_picture", "No picture: compares legs, judges nothing a proven picture can show (listed, not drawn)"),
                       ("debt", "Not yet declared (the retrofit's debt)")):
        if meta.get(key):
            rest.append("<h2>%s — %d</h2><div class=\"mut\">%s</div>" % (title, len(meta[key]), html.escape(", ".join(meta[key]))))
    builds = "".join("<li>%s: %s</li>" % (html.escape(k), html.escape(v)) for k, v in meta.get("builds", {}).items())
    builds += "".join("<li>%s</li>" % html.escape(v) for v in meta.get("provenance", []))
    body = ('<h1>Comparative capture sheets</h1><div class="mut">commit %s · run %s · each picture proven against what its gate '
            'logged (#291)</div><ul class="mut">%s</ul>%s%s%s<h2>The gates</h2><table class="grid">%s</table>%s') % (
                html.escape(meta["commit"]), html.escape(meta["date"]), builds, "".join(top), legend_html(), "".join(idx),
                verdicts, "".join(rest))
    (out_dir / "index.html").write_text(page_doc("Proof Sheets", meta, body))
    meta["undefined_tags"] = undefined
    return out_dir / "index.html"


def build_key(rompath, set_):
    r = subprocess.run([sys.executable, str(ROOT / "tools/build_fingerprint.py"), rompath, "--set", set_],
                       capture_output=True, text=True)
    v = r.stdout.strip().splitlines()[-1] if r.stdout.strip() else "?"
    return ("registered: %s" % v) if r.returncode == 0 else ("UNREGISTERED: %s" % v)


# ── S3: the commit, built in a clean checkout (14z-205) ─────────────────────────────────────────────────────────
# What each runner-default track is built as: (set, the commit's frozen reference in tests/test_m3a_reproducible.sh,
# env, argv). The recipe is that gate's own (the four tracks, then the merged image from its inputs); a recipe that
# drifts from the commit's is caught by the fingerprint check against EXPECT_*, not trusted.
WIDE_FLAGS = "--allow-plausible --tripwire-open --profile cps2-wide-v1"
STOCK_FLAGS = "--allow-plausible --tripwire-open"
TENANT_FLAGS = "--profile cps2-wide-v1 --allow-plausible --tripwire-open"
TRACKS = ("DON", "STOCK", "HUI", "PYR", "MERGED")
TRACK_SET = {"DON": "vsavjw", "STOCK": "vsavj", "HUI": "vsavjw", "PYR": "vsavjw", "MERGED": "vsavjw"}
TRACK_EXPECT = {"DON": "WIDE", "STOCK": "STOCK", "HUI": "HUI", "PYR": "PYR", "MERGED": "MERGED"}


def build_steps(names, tree, romdir):
    """-> [(label, env, argv)] in order, run from the checkout's root."""
    wide = str(Path(tree) / "build/wide0/rompath/vsavjw.zip")
    return [
        ("wide0", {}, ["python3", "tools/build_wide_romset.py", romdir, "build/wide0/rompath", "--qsound", "2", "--gfx", "4", "--prg", "4"]),
        ("DON", {"KEY_SET": "vsavj", "WIDE_ROMSET": wide, "GEN_FLAGS": WIDE_FLAGS}, ["tools/build_donovan.sh", "6", names["DON"]]),
        ("STOCK", {"GEN_FLAGS": STOCK_FLAGS}, ["tools/build_donovan.sh", "6", names["STOCK"]]),
        ("HUI", {"TENANT_MANIFEST": "build/manifest/huitzil.toml", "TENANT_CHAR": "0x10", "WIDE_ROMSET": wide, "GEN_FLAGS": TENANT_FLAGS},
         ["tools/build_donovan.sh", "6", names["HUI"]]),
        ("PYR", {"TENANT_MANIFEST": "build/manifest/pyron.toml", "TENANT_CHAR": "0x11", "WIDE_ROMSET": wide, "GEN_FLAGS": TENANT_FLAGS},
         ["tools/build_donovan.sh", "6", names["PYR"]]),
        ("merged inputs", {}, ["tools/ensure_merged_inputs.sh"]),
        ("MERGED", {"WIDE_ROMSET": wide}, ["tools/build_merged.sh", names["MERGED"]]),
    ]


def frozen_references(tree):
    """The commit's own frozen track fingerprints: {WIDE|STOCK|HUI|PYR|MERGED: sha1} from its test_m3a_reproducible.sh."""
    p = Path(tree) / "tests/test_m3a_reproducible.sh"
    if not p.exists():
        return {}
    return dict(re.findall(r'^EXPECT_(WIDE|STOCK|HUI|PYR|MERGED)="([0-9a-f]{40})"', p.read_text(), re.M))


def fingerprint(tree, rompath, set_, romdir):
    r = subprocess.run([sys.executable, "tools/build_fingerprint.py", "%s;%s" % (rompath, romdir), "--set", set_, "--sha-only"],
                       cwd=tree, capture_output=True, text=True)
    return r.stdout.strip().splitlines()[-1] if r.returncode == 0 and r.stdout.strip() else None


def check_builds(built, expect):
    """built {track: fp|None}, expect {WIDE|...: fp} -> problems ([] = every track is the commit's frozen reference)."""
    out = []
    for t in TRACKS:
        want = expect.get(TRACK_EXPECT[t])
        if not want:
            out.append("%s: the commit freezes no reference fingerprint (EXPECT_%s) — nothing says this build is the commit's" % (t, TRACK_EXPECT[t]))
        elif built.get(t) != want:
            out.append("%s: built %s, the commit's frozen reference is %s — the commit does not reproduce its own build" % (t, built.get(t), want))
    return out


def build_commit(tree, romdir, logs, reuse):
    """Build the runner-default tracks in the checkout. -> (record, problems)."""
    names = runner_defaults(tree)                        # the checkout's own names (the commit's, or a control's)
    missing = [t for t in TRACKS if t not in names]
    if missing:
        return None, ["the commit's tests/run_all_emulator.sh names no default for %s" % ", ".join(missing)]
    rec_p = Path(tree) / ".proof_build.json"
    logs.mkdir(parents=True, exist_ok=True)
    if not (reuse and rec_p.exists()):
        r = subprocess.run([sys.executable, "tools/audit_roms.py", romdir], cwd=tree, capture_output=True, text=True)
        (logs / "audit_roms.log").write_text(r.stdout + r.stderr)
        if r.returncode != 0:
            return None, ["ROMDIR %s does not match the commit's docs/checksums.txt (CLAUDE.md §3; %s)" % (romdir, logs / "audit_roms.log")]
        for label, env, argv in build_steps(names, tree, romdir):
            t0 = time.time()
            print("   build %s: %s" % (label, " ".join(argv)), flush=True)
            with open(logs / ("%s.log" % label.replace(" ", "_")), "w") as lf:
                rc = subprocess.run(argv, cwd=tree, env=dict(os.environ, ROMDIR=romdir, **env), stdout=lf,
                                    stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL).returncode
            print("     exit %d, %ds" % (rc, time.time() - t0), flush=True)
            if rc != 0:
                return None, ["the %s build failed (exit %d; %s)" % (label, rc, logs / ("%s.log" % label.replace(" ", "_")))]
    built = {t: fingerprint(tree, names[t] + "/rompath", TRACK_SET[t], romdir) for t in TRACKS}
    expect = frozen_references(tree)
    rec = {"tracks": {t: {"dir": names[t], "set": TRACK_SET[t], "fingerprint": built[t], "frozen": expect.get(TRACK_EXPECT[t])} for t in TRACKS}}
    rec_p.write_text(json.dumps(rec, indent=1))
    return rec, check_builds(built, expect)


def tag_program_key(tag):
    """The freeze tag's own `program key` line (its message), or None."""
    r = subprocess.run(["git", "cat-file", "-p", tag], cwd=TOOL_ROOT, capture_output=True, text=True)
    m = re.search(r"^program key\s+([0-9a-f]{40})\s*$", r.stdout, re.M)
    return m.group(1) if m else None


def control_check(tag, track, built, want):
    """-> problems: the control track must be the build the tag names (its `program key`), or the run says so."""
    if not want:
        return ["%s carries no `program key` line: nothing says which build it froze" % tag]
    if built != want:
        return ["%s: %s built %s, the tag's program key is %s" % (tag, track, built, want)]
    return []


def control_build(tag, track, out, romdir, bundle):
    """A control build: `tag`'s commit in a second clean checkout, built by the recipe, every track its own frozen
    reference and `track` the tag's program key. -> (build dir | None, provenance line, problems). A checkout and build
    a previous run of this tag made are re-used and re-fingerprinted (the commit is fixed, so the build is too)."""
    sha = subprocess.run(["git", "rev-parse", "--verify", "--quiet", tag + "^{commit}"], cwd=TOOL_ROOT,
                         capture_output=True, text=True).stdout.strip()
    if not sha:
        return None, "", ["%s does not resolve to a commit in %s (a --host run carries no tags: not supported)" % (tag, TOOL_ROOT)]
    ctree = (Path(out).parent / ("%s.ctl.tree" % sha[:12])).resolve()
    reuse = ctree.exists() and any(ctree.iterdir())
    if bundle is None and not reuse:
        bundle = Path(out) / ("ctl_%s.bundle" % sha[:12])
        err = make_bundle(sha, bundle)
        if err:
            return None, "", ["could not bundle %s (%s): %s" % (tag, sha[:12], err)]
    print("== the control build %s (%s): a second clean checkout at %s" % (tag, sha[:12], ctree), flush=True)
    err = make_checkout(sha, ctree, bundle, reuse)
    if err:
        return None, "", ["%s: %s" % (tag, err)]
    rec, problems = build_commit(ctree, romdir, Path(out) / ("build_logs_ctl_%s" % sha[:12]), reuse and (ctree / ".proof_build.json").exists())
    if problems:
        return None, "", ["%s: %s" % (tag, p) for p in problems]
    tr = rec["tracks"][track]
    want = tag_program_key(tag)
    problems = control_check(tag, track, tr["fingerprint"], want)
    if problems:
        return None, "", problems
    d = ctree / tr["dir"]
    prov = "control build, from %s, not the commit: %s %s (%s) = %s's frozen reference and the tag's program key, built in a second clean checkout (%s)" % (
        tag, track, tr["dir"], tr["fingerprint"], sha[:12], ctree)
    return d, prov, []


def variant_build(v, tree, romdir, logs, reuse):
    """A gate-declared variant, built in the clean checkout's build/ by the commit's own builder (`. <lib>; <func> <work>`,
    which sets OUTBASE). -> (OUTBASE | None, provenance line, problems). Its fingerprint is stated, never frozen: there
    is no reference to refuse it against (ruled 2026-10-22)."""
    tree = Path(tree).resolve()
    work = tree / "build" / "sheet_variants" / v["func"]
    log = Path(logs) / ("variant_%s.log" % v["func"])
    Path(logs).mkdir(parents=True, exist_ok=True)
    if not (tree / v["lib"]).is_file():
        return None, "", ["%s names %s, which the commit does not carry" % (v["func"], v["lib"])]
    outbase = work / "build"
    if not (reuse and (outbase / "rompath").is_dir()):
        shutil.rmtree(work, ignore_errors=True)
        work.mkdir(parents=True)
        print("   build variant %s (%s) in %s" % (v["func"], v["lib"], work), flush=True)
        t0 = time.time()
        with open(log, "w") as lf:
            r = subprocess.run(["sh", "-c", '. "./$1" && unset TENANT13_OUTBASE && OUTBASE= && %s "$2" "" && echo "VARIANT_OUTBASE=$OUTBASE"' % v["func"],
                                "sh", v["lib"], str(work)], cwd=tree, env=dict(os.environ, ROMDIR=romdir), stdout=lf,
                               stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL)
        print("     exit %d, %ds" % (r.returncode, time.time() - t0), flush=True)
        said = re.findall(r"^VARIANT_OUTBASE=(.*)$", log.read_text(errors="replace"), re.M)
        if r.returncode != 0 or not said:
            return None, "", ["the variant %s did not build (exit %d; %s)" % (v["func"], r.returncode, log)]
        outbase = Path(said[-1].strip())
    problem = ours_build_problem(str(outbase / "rompath"), tree)
    if problem:
        return None, "", ["the variant %s: %s" % (v["func"], problem)]
    fp = fingerprint(tree, str(outbase / "rompath"), v["set"], romdir)
    if not fp:
        return None, "", ["the variant %s: no fingerprint of %s (%s)" % (v["func"], outbase / "rompath", v["set"])]
    prov = "gate-built variant, from the commit, no frozen reference: %s (%s), %s %s = %s, built in the clean checkout (%s)" % (
        v["func"], v["lib"], v["set"], outbase.relative_to(tree), fp, tree)
    return outbase, prov, []


def is_tracked(tree, rel):
    r = subprocess.run(["git", "ls-files", "--", rel], cwd=tree, capture_output=True, text=True)
    return bool(r.stdout.strip())


def ours_build_problem(rompath, tree):
    """None when an `ours` leg ran on a build made in the clean checkout's build/ (a clean checkout has no untracked
    build/ entry until this run makes one: the S3 build step, or a gate building from the commit's own sources);
    else why the leg is not the commit's build."""
    tree = Path(tree).resolve()
    first = (rompath or "").split(";")[0].strip()
    if not first:
        return "ours names no rom path"
    p = Path(first) if os.path.isabs(first) else tree / first
    p = p.resolve()
    if not str(p).startswith(str((tree / "build").resolve()) + os.sep):
        return "ours ran on %s, outside the clean checkout's build/: not a build this run made from the commit" % first
    rel = str(p.relative_to(tree))
    if is_tracked(tree, rel):
        return "ours ran on %s, a tracked path of the commit, not a build" % first
    return None


def commit_check(sheets, tree):
    """Mark every picture of an `ours` leg that did not run on the commit's build NOT THE JUDGED RUN (S3). In place."""
    for s in sheets:
        bad = {}
        for lg in s["legs"]:
            if lg["role"] == "ours":
                why = ours_build_problem(lg["rompath"], tree)
                if why:
                    bad[lg["leg"]] = why
        for c in s["cols"]:
            pairs = list(c["cells"].items()) + [(leg, x) for leg, xs in c.get("strip", {}).items() for x in xs]
            for leg, x in pairs:
                if leg in bad and not x.get("_s3"):
                    x["why"] = "%s (its own proof: %s %s)" % (bad[leg], x["status"], x["why"])
                    x["status"] = "NOT THE JUDGED RUN"
                    x["_s3"] = True
    return sheets


def emulators():
    out = []
    bins = [os.environ["MAME_BIN"]] if os.environ.get("MAME_BIN") else [
        os.path.expanduser("~/.cache/vampire-saved/mame/cps2"), os.path.expanduser("~/.cache/vampire-saved/mame-ref/cps2")]
    for b in bins:
        if os.path.exists(b):
            r = subprocess.run(["shasum" if shutil.which("shasum") else "sha1sum", b], capture_output=True, text=True)
            out.append("emulator %s sha1 %s (this host's pinned build, not built from the commit)" % (b, (r.stdout.split() or ["?"])[0]))
    return out


def make_checkout(sha, tree, bundle, reuse):
    """A clean checkout of exactly `sha` at `tree`, cloned from a bundle. -> problem or None."""
    tree = Path(tree)
    if tree.exists() and any(tree.iterdir()):
        if not reuse:
            return "%s exists; remove it, or pass --reuse-tree to use the checkout a previous run of this commit made" % tree
        head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=tree, capture_output=True, text=True).stdout.strip()
        dirty = subprocess.run(["git", "status", "--porcelain", "--untracked-files=no"], cwd=tree, capture_output=True, text=True).stdout.strip()
        if head != sha or dirty:
            return "%s is not a clean checkout of %s (HEAD %s, %d modified tracked file(s))" % (tree, sha[:12], head[:12], len(dirty.splitlines()))
        return None
    tree.mkdir(parents=True, exist_ok=True)
    # init + fetch every ref of the bundle: a clone takes only refs/heads and refs/tags, and the bundle's one ref is
    # the temporary refs/proof-sheets/* (make_bundle), so a clone would arrive empty (found on PILOT, 14z-205)
    for argv in (["git", "-C", str(tree), "init", "--quiet"],
                 ["git", "-C", str(tree), "fetch", "--quiet", str(bundle), "+refs/*:refs/bundle/*"],
                 ["git", "-C", str(tree), "checkout", "--quiet", "--detach", sha]):
        r = subprocess.run(argv, capture_output=True, text=True)
        if r.returncode != 0:
            return "%s: %s" % (" ".join(argv[:3]), (r.stderr.strip().splitlines() or ["failed"])[-1])
    return None


def make_bundle(sha, path):
    """A bundle of the commit's history, through a temporary ref (git bundles refs, not bare commits); the ref is gone after."""
    ref = "refs/proof-sheets/run-%d" % os.getpid()
    try:
        subprocess.run(["git", "update-ref", ref, sha], cwd=TOOL_ROOT, check=True)
        r = subprocess.run(["git", "bundle", "create", str(path), ref], cwd=TOOL_ROOT, capture_output=True, text=True)
        return None if r.returncode == 0 else (r.stderr.strip().splitlines() or ["git bundle failed"])[-1]
    finally:
        subprocess.run(["git", "update-ref", "-d", ref], cwd=TOOL_ROOT)


# The hosts (docs/project/operations.md / the remote machines): how to reach a shell, where files land for scp, where
# that place is seen from the run's shell, the ROMDIR, and whether the run may be detached. PILOT is a Linux VM;
# ERIS reaches WSL2 through wsl.exe, whose distro stops when no client is open, so its run is held by the ssh
# (UNTESTED: written 14z-205 while ERIS was unreachable).
HOSTS = {
    "pilot": {"ssh": "pilot", "shell": "sh -s", "xfer": "{dir}", "xfer_seen": "$HOME/{dir}", "run": "$HOME/{dir}",
              "romdir": "$HOME/roms", "detach": True, "pre": ""},
    "eris": {"ssh": "eris", "shell": "wsl.exe -e sh -s", "xfer": "proof_sheets_xfer/{sha}",
             "xfer_seen": "/mnt/c/Users/chaton/proof_sheets_xfer/{sha}", "run": "$HOME/{dir}", "romdir": None,
             "detach": False, "pre": "unset DISPLAY WAYLAND_DISPLAY PULSE_SERVER XDG_RUNTIME_DIR; "
                                     "export SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy"},
}


def ssh_script(h, script, timeout):
    """Run a shell script on the host (stdin), bounded. -> CompletedProcess (rc 124 on timeout)."""
    body = '. "$HOME/.profile" >/dev/null 2>&1\n%s\n%s\n' % (h["pre"], script)
    try:
        return subprocess.run(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=15", h["ssh"], h["shell"]], input=body,
                              capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess([], 124, "", "ssh timed out after %ds" % timeout)


def q(s):
    return "'" + str(s).replace("'", "'\\''") + "'"


def host_run(a, sha):
    if a.host not in HOSTS:
        print("REFUSED: unknown host %r (hosts: %s)" % (a.host, ", ".join(sorted(HOSTS))))
        return 2
    h = HOSTS[a.host]
    romdir = a.host_romdir or h["romdir"]
    if not romdir:
        print("REFUSED: --host %s needs --host-romdir (no default ROMDIR is recorded for it)" % a.host)
        return 2
    s12 = sha[:12]
    d = "%s/%s" % ((a.host_dir or "proof_sheets").rstrip("/"), s12)
    run, xfer, seen = h["run"].format(dir=d), h["xfer"].format(dir=d, sha=s12), h["xfer_seen"].format(dir=d, sha=s12)
    local_out = Path(a.out or TOOL_ROOT / "build" / "sheets" / s12).resolve()
    local_out.mkdir(parents=True, exist_ok=True)
    stage = local_out / "host_stage"
    shutil.rmtree(stage, ignore_errors=True)
    stage.mkdir()
    err = make_bundle(sha, stage / "c.bundle")
    if err:
        print("REFUSED: could not bundle %s: %s" % (sha[:12], err))
        return 2
    shutil.copyfile(Path(__file__).resolve(), stage / "proof_sheets_s3.py")
    r = ssh_script(h, "set -e; rm -rf %s; mkdir -p %s %s" % (run, run, seen if seen != run else run), 60)
    if r.returncode != 0:
        print("REFUSED: %s unreachable or refused the work dir: %s" % (a.host, (r.stderr or r.stdout).strip()[-300:]))
        return 2
    t0 = time.time()
    try:
        rc = subprocess.run(["scp", "-q", "-o", "BatchMode=yes", str(stage / "c.bundle"), str(stage / "proof_sheets_s3.py"),
                             "%s:%s/" % (h["ssh"], xfer)], timeout=1800).returncode
    except subprocess.TimeoutExpired:
        rc = 124
    if rc != 0:
        print("REFUSED: sending the bundle to %s failed (exit %d)" % (a.host, rc))
        return 2
    print("   sent the bundle and the tool to %s:%s (%ds)" % (a.host, run, time.time() - t0), flush=True)
    opts = "".join(" --gate %s" % q(g) for g in (a.gate or [])) + (" --char %s" % q(a.char) if a.char else "") + \
        (" --ticket %s" % q(a.ticket) if a.ticket else "") + " --jobs %d" % a.jobs
    cmd = ("cd %s && { [ %s = %s ] || cp %s/c.bundle %s/proof_sheets_s3.py %s/; } && "
           "ROMDIR=%s python3 proof_sheets_s3.py run %s --bundle c.bundle --tree tree --out out%s > run.log 2>&1; echo $? > rc"
           % (run, q(seen), q(run), seen, seen, run, romdir, sha, opts))
    if h["detach"]:
        r = ssh_script(h, "cd %s || exit 1\nrm -f rc\nnohup setsid sh -c %s > /dev/null 2>&1 < /dev/null &\necho $! > pid\necho started"
                       % (run, q(cmd)), 60)
        held = None
        if "started" not in r.stdout:
            print("REFUSED: could not start the run on %s: %s" % (a.host, (r.stderr or r.stdout).strip()[-300:]))
            return 2
    else:                                               # held: the ssh keeps WSL2's distro alive for the whole run
        held = subprocess.Popen(["ssh", "-o", "BatchMode=yes", h["ssh"], h["shell"]], stdin=subprocess.PIPE,
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, text=True)
        held.stdin.write('. "$HOME/.profile" >/dev/null 2>&1\n%s\n%s\n' % (h["pre"], cmd))
        held.stdin.close()
    t0, seen_output, last = time.time(), False, ""
    while True:
        time.sleep(15 if not seen_output else 60)
        r = ssh_script(h, "cd %s && { cat rc 2>/dev/null || echo RUNNING; }; wc -c < run.log 2>/dev/null || echo 0; tail -n 1 run.log 2>/dev/null" % run, 60)
        lines = r.stdout.splitlines()
        state = lines[0].strip() if lines else "?"
        size = int(lines[1].strip()) if len(lines) > 1 and lines[1].strip().isdigit() else 0
        tail = lines[2] if len(lines) > 2 else ""
        seen_output = seen_output or size > 0
        if tail != last:
            print("   [%s %ds] %s" % (a.host, time.time() - t0, tail[:160]), flush=True)
            last = tail
        if state != "RUNNING" and state.isdigit():
            break
        if not seen_output and time.time() - t0 > 180:          # the early poll: a run that writes nothing is not running
            print("FAILED: the run on %s wrote no output in 180 s" % a.host)
            host_kill(h, run, held)
            return 1
        if time.time() - t0 > a.host_timeout:
            print("FAILED: the run on %s passed --host-timeout %ds; stopped" % (a.host, a.host_timeout))
            host_kill(h, run, held)
            return 1
    if held:
        held.wait(timeout=120)
    remote_rc = int(state)
    r = ssh_script(h, "cd %s && tar -cf %s/out.tar --exclude='out/gates/*/capture' out run.log && echo packed" % (run, seen), 1800)
    if "packed" not in r.stdout:
        print("FAILED: could not pack the page on %s: %s" % (a.host, (r.stderr or r.stdout).strip()[-300:]))
        return 1
    try:
        rc = subprocess.run(["scp", "-q", "-o", "BatchMode=yes", "%s:%s/out.tar" % (h["ssh"], xfer), str(stage / "out.tar")], timeout=3600).returncode
    except subprocess.TimeoutExpired:
        rc = 124
    if rc != 0:
        print("FAILED: fetching the page from %s failed (exit %d)" % (a.host, rc))
        return 1
    subprocess.run(["tar", "-xf", str(stage / "out.tar"), "-C", str(stage)], check=True)
    for p in (stage / "out").iterdir():
        dst = local_out / p.name
        if dst.is_dir():
            shutil.rmtree(dst)
        elif dst.exists():
            dst.unlink()
        shutil.move(str(p), str(dst))
    shutil.move(str(stage / "run.log"), str(local_out / ("host_run_%s.log" % a.host)))
    shutil.rmtree(stage, ignore_errors=True)
    print("   the run on %s exited %d after %ds; its log is %s" % (a.host, remote_rc, time.time() - t0, local_out / ("host_run_%s.log" % a.host)))
    if (local_out / "index.html").exists() and remote_rc == 0:
        print("WROTE %s" % (local_out / "index.html"))
    return remote_rc


def host_kill(h, run, held):
    ssh_script(h, "cd %s && [ -f pid ] && kill -TERM -$(cat pid) 2>/dev/null; kill -TERM $(cat pid) 2>/dev/null; echo 130 > rc" % run, 60)
    if held:
        held.kill()


# ── commands ────────────────────────────────────────────────────────────────────────────────────────────────────
def cmd_run(a):
    global ROOT
    if a.host:
        if a.host not in HOSTS:
            print("REFUSED: unknown host %r (hosts: %s)" % (a.host, ", ".join(sorted(HOSTS))))
            return 2
        sha = subprocess.run(["git", "rev-parse", a.commit + "^{commit}"], cwd=TOOL_ROOT, capture_output=True, text=True).stdout.strip()
        if not sha:
            print("REFUSED: %s is not a commit" % a.commit)
            return 2
        return host_run(a, sha)
    if not os.environ.get("ROMDIR"):
        print("REFUSED: set ROMDIR")
        return 2
    romdir = str(Path(os.environ["ROMDIR"]).expanduser().resolve())
    os.environ["ROMDIR"] = romdir
    if a.bundle:                                         # on a host: the commit arrives as a bundle, named by its full sha
        sha = a.commit if re.match(r"^[0-9a-f]{40}$", a.commit) else ""
        if not sha:
            print("REFUSED: with --bundle the commit is named by its full 40-hex sha, not %r" % a.commit)
            return 2
        bundle = Path(a.bundle).resolve()
    else:
        sha = subprocess.run(["git", "rev-parse", a.commit + "^{commit}"], cwd=TOOL_ROOT, capture_output=True, text=True).stdout.strip()
        if not sha:
            print("REFUSED: %s is not a commit" % a.commit)
            return 2
        bundle = None
    out = Path(a.out or TOOL_ROOT / "build" / "sheets" / sha[:12]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    tree = Path(a.tree or out.parent / ("%s.tree" % sha[:12])).resolve()
    if bundle is None and not (a.reuse_tree and tree.exists()):
        bundle = out / "c.bundle"
        err = make_bundle(sha, bundle)
        if err:
            print("REFUSED: could not bundle %s: %s" % (sha[:12], err))
            return 2
    print("== the clean checkout of %s at %s" % (sha[:12], tree), flush=True)
    err = make_checkout(sha, tree, bundle, a.reuse_tree)
    if err:
        print("REFUSED: %s" % err)
        return 2
    if not (tree / "tests/lib/sheet.sh").exists():
        print("REFUSED: %s predates #291 S1 (no tests/lib/sheet.sh): no gate of it declares a sheet" % sha[:12])
        return 2
    ROOT = tree                                          # from here every gate, script, note and registry is the commit's
    print("== building the commit's tracks in the checkout", flush=True)
    rec, problems = build_commit(tree, romdir, out / "build_logs", a.reuse_tree)
    for p in problems:
        print("REFUSED: %s" % p)
    if problems:
        return 2
    prov = ["commit %s, built in a clean checkout (%s)" % (sha, tree)]
    prov += ["%s %s (%s): %s = the commit's frozen reference" % (t, v["dir"], v["set"], v["fingerprint"]) for t, v in rec["tracks"].items()]
    prov += emulators()
    for p in prov:
        print("   " + p, flush=True)
    rows = registry_gates(ROOT / "tests/ci_emulator.tsv")
    meta = {"commit": sha, "date": time.strftime("%Y-%m-%d %H:%M"), "gates": [], "no_reference_leg": [], "no_picture": [], "debt": [],
            "builds": {}, "provenance": prov}
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
    controls = {}                                        # (tag, track) -> (dir, provenance, problems), built once a run
    variants = {}                                        # (lib, func, set) -> (OUTBASE, provenance, problems), built once a run
    for r in declared:
        g = r[0]
        sd = out / "gates" / g
        extra, ctl_lines, ctl_problems = {}, [], []
        cbs, errs = parse_sheet_builds(ROOT / "tests" / (g + ".sh"))
        ctl_problems += errs
        for cb in cbs:
            key = (cb["tag"], cb["track"])
            if key not in controls:
                controls[key] = control_build(cb["tag"], cb["track"], out, romdir, bundle)
                if controls[key][1]:
                    meta["provenance"].append(controls[key][1])
            d, prov, probs = controls[key]
            ctl_problems += probs
            if d is not None:
                extra[cb["var"]] = str(d)
                ctl_lines.append("%s = %s" % (cb["var"], prov))
        var_lines = []
        vds, errs = parse_sheet_variants(ROOT / "tests" / (g + ".sh"))
        ctl_problems += errs
        for v in vds:
            key = (v["lib"], v["func"], v["set"])
            if key not in variants:
                variants[key] = variant_build(v, tree, romdir, out / "build_logs", a.reuse_tree)
                if variants[key][1]:
                    meta["provenance"].append(variants[key][1])
            d, prov, probs = variants[key]
            ctl_problems += probs
            if d is not None:
                extra[v["var"]] = str(d)
                var_lines.append("%s = %s" % (v["var"], prov))
        if ctl_problems:
            for p in ctl_problems:
                print("REFUSED (%s): %s" % (g, p), flush=True)
            meta["gates"].append({"gate": g, "rc": 2, "seconds": 0, "tickets": [],
                                  "verdict": "NOT RUN: its control build or variant was refused (%s)" % "; ".join(ctl_problems)[:300]})
            continue
        print("== %s: running the gate with SHEET_OUT" % g, flush=True)
        res = run_gate(r, sd, out / ("%s.log" % g), extra)
        res["control_builds"] = ctl_lines
        res["variant_builds"] = var_lines
        print("   %s (exit %d, %ds)" % (res["verdict"], res["rc"], res["seconds"]), flush=True)
        res["tickets"] = sorted(set(re.findall(r"#(\d+)", "\n".join(leading_block(ROOT / "tests" / (g + ".sh"))))))
        if not (sd / "sheet.tsv").exists():
            res["verdict"] += " — the gate wrote no sheet"
            meta["gates"].append(res)
            continue
        print("   capturing and proving", flush=True)
        res["sheets"] = commit_check(prove_dir(sd, a.jobs), tree)
        (sd / "proof.json").write_text(json.dumps(res["sheets"], indent=1))
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
    for u in meta.get("undefined_tags", []):     # S4-C: a tag the page shows but defines nowhere fails the run, loudly
        print("UNDEFINED TAG: %s" % u)
    return 1 if meta.get("undefined_tags") else 0


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
                print("%s\t%s\t%s\tf%s\t%s\t%s\t%s\t%s" % (s["sid"], c["label"], leg, x["frame"], x["status"], x["why"], x.get("fighters"), who_cell(x)))
            for leg, xs in c.get("strip", {}).items():      # S4-D: a span's other frames, labelled `<label> [span]`
                for x in xs:
                    if not x.get("moment"):
                        print("%s\t%s [span]\t%s\tf%s\t%s\t%s\t%s\t%s" % (s["sid"], c["label"], leg, x["frame"], x["status"], x["why"], x.get("fighters"), who_cell(x)))
    return 0


def cmd_page(a):
    meta = json.loads((Path(a.dir) / "meta.json").read_text())
    print("WROTE %s" % page(a.dir, meta))
    return 0


def cmd_commitcheck(a):
    sheets = commit_check(json.loads(Path(a.proof).read_text()), a.tree)
    for s in sheets:
        for c in s["cols"]:
            for leg, x in c["cells"].items():
                print("%s\t%s\t%s\tf%s\t%s\t%s" % (s["sid"], c["label"], leg, x["frame"], x["status"], x["why"]))
    return 0


def cmd_census(a):
    rows, problems = census(a.tests, a.registry, a.debt, a.span_debt)
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
    r.add_argument("--tree", help="the clean checkout (default build/sheets/<commit>.tree)")
    r.add_argument("--reuse-tree", action="store_true", help="use the checkout and builds a previous run of this commit made")
    r.add_argument("--bundle", help="clone the commit from this bundle (what a --host run does on the host)")
    r.add_argument("--host", help="run on pilot or eris and bring the page back")
    r.add_argument("--host-dir", help="the work dir under the host's home (default proof_sheets)")
    r.add_argument("--host-romdir", help="ROMDIR on the host (PILOT's default: ~/roms)")
    r.add_argument("--host-timeout", type=int, default=8 * 3600)
    p = sub.add_parser("prove")
    p.add_argument("dir")
    p.add_argument("--jobs", type=int, default=4)
    k = sub.add_parser("commitcheck")
    k.add_argument("proof")
    k.add_argument("tree")
    g = sub.add_parser("page")
    g.add_argument("dir")
    c = sub.add_parser("census")
    c.add_argument("--tests", default=str(ROOT / "tests"))
    c.add_argument("--registry", default=str(ROOT / "tests/ci_emulator.tsv"))
    c.add_argument("--debt", default=str(ROOT / "tests/expected/sheet_debt.txt"))
    c.add_argument("--span-debt", default=str(ROOT / "tests/expected/sheet_span_debt.txt"))
    a = ap.parse_args(argv)
    return {"run": cmd_run, "prove": cmd_prove, "page": cmd_page, "commitcheck": cmd_commitcheck, "census": cmd_census}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
