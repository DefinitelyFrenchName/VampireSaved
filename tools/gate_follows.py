#!/usr/bin/env python3
"""gate_follows.py — THE ONE READER of `# FOLLOWS:`, the repo paths an emulator-tier
gate's verdict depends on (GitHub #171 slice Q3, ruled 2026-09-24: "Header line").

  python3 tools/gate_follows.py                      # census over tests/ci_emulator.tsv: declares / undeclared
  python3 tools/gate_follows.py --reconcile          # every declaring gate's references vs its declaration
  python3 tools/gate_follows.py --refs test_x        # what one gate's text (and its sourced libs) references
  python3 tools/gate_follows.py --subjects mame      # a lane's derived subjects (the union the carry tool uses)
  python3 tools/gate_follows.py --root DIR ...       # over a copy of the tree (the gate's controls)

THE GRAMMAR — one field in the gate's LEADING COMMENT BLOCK (every `#` line after the
shebang up to the first non-comment line; a bare `#` continues the block):

    # FOLLOWS: <prefix> <prefix> ...
    #   <prefix> ...                      (continuation: `#` + at least two spaces)

Each token is a repo-relative PATH PREFIX in tests/ci_cadence.tsv's sense — a
directory (`tests/replays/`), a file (`tools/run_replay_mame.sh`) or a stem
(`tools/gen_`). Two paths are IMPLIED and never written: the gate's own script and
`tests/ci_emulator.tsv` (the registry carries every row's args and timeout). A gate is
DECLARES when the field is present once with at least one token; else UNDECLARED.

THE RECONCILIATION (the control that makes a declaration honest): the repo paths a
gate's TEXT references — every `tests/…`, `tools/…`, `docs/…`, `emu/…`, `build/manifest…`
token in a non-comment line of the script and, transitively, of the RUN-TIME HARNESS it
reaches (every `tests/lib/*.sh` it sources and every `tools/run_*.sh` runner it calls —
not the build chain, whose subject is the romset), plus the tokens of its registry row's
`args` — must each be COVERED by a
declared prefix (the reference starts with the prefix). A reference composed from a
variable (`tests/replays/$rpl.rpl`) is cut at the variable, so only a declaration at
least as wide as `tests/replays/` covers it. Untracked build outputs (`build/…` other
than `build/manifest`) are not references: their source is the manifest and the tools
that build them, which the gate declares if it reads them. A declaration can therefore
be WIDER than the text shows (a path the gate reaches through a tool, or the maintainer
knows it follows) but never NARROWER than what the text demonstrably reads.

WHY ONE READER: `tests/test_gate_follows.sh` freezes the census and runs the
reconciliation; `tools/audit_lane_carry.py` derives a lane's subjects from the
declarations; the staleness gate (slice Q4) diffs them against the commit the newest
emulator run recorded. Board-, game- and project-agnostic.
"""
import argparse, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gate_descriptions import leading_block, CONT_RE  # the one leading-block definition

FIELD_RE = re.compile(r"^# FOLLOWS:(.*)$")
ANY_FIELD_RE = re.compile(r"^# [A-Z][A-Z-]+:")
# a repo-relative path token in script text; cut at the first variable/glob character
REF_RE = re.compile(r"(?<![\w/.@-])((?:tests|tools|docs|emu|build/manifest)(?:/[A-Za-z0-9_.*{}$/-]*)?)")
CUT_RE = re.compile(r"[${*]")
SOURCE_RE = re.compile(r"""^\s*(?:\.|source)\s+"?\$\{?REPO\}?/(tests/lib/[A-Za-z0-9_.-]+\.sh)"?""")
# the RUN-TIME HARNESS a gate reaches through: shared libraries and the replay/emulator
# runners are scanned transitively (their references are the gate's); the BUILD chain
# (tools/build_*.sh, tests/run_suite.sh, tools/pack_build.sh) is not — its subject is the
# romset, and a gate that builds declares build/manifest/ and the builder it calls.
HARNESS_RE = re.compile(r"^(tests/lib/[A-Za-z0-9_.-]+\.sh|tools/(?:run|tap)_[a-z0-9_]+\.sh|tools/force_pick_probe\.sh)$")
IMPLIED = ("tests/ci_emulator.tsv",)
REGISTRY = "tests/ci_emulator.tsv"


def declared(text):
    """-> (prefixes: [str], problems: [str]) for one gate's text."""
    toks, problems, seen, cur = [], [], 0, False
    for l in leading_block(text):
        m = FIELD_RE.match(l)
        if m:
            seen += 1
            toks += m.group(1).split()
            cur = True
            continue
        if cur:
            c = CONT_RE.match(l)
            if c and not ANY_FIELD_RE.match(l):
                toks += c.group(1).split()
                continue
            cur = False
    if seen == 0:
        problems.append("no FOLLOWS line")
    elif seen > 1:
        problems.append("duplicate FOLLOWS")
    elif not toks:
        problems.append("empty FOLLOWS")
    for t in toks:
        if not t.startswith(("tests/", "tools/", "docs/", "emu/", "build/manifest", ".claude/")):
            problems.append(f"not a repo path prefix: {t}")
    return toks, problems


def registry_rows(root):
    rows = {}
    p = os.path.join(root, REGISTRY)
    if not os.path.exists(p):
        return rows
    for line in open(p, encoding="utf-8", errors="replace"):
        line = line.rstrip("\r\n")
        if not line or line.startswith("#"):
            continue
        f = line.split("\t")
        if len(f) < 3 or not f[0]:
            continue
        rows[f[0]] = {"lane": f[1], "scope": f[2], "cadence": f[3] if len(f) > 3 else "",
                      "args": f[4] if len(f) > 4 else "", "timeout": f[6] if len(f) > 6 else ""}
    return rows


def _body_lines(text):
    """Non-comment lines of a script, trailing ` # …` comments stripped, header excluded."""
    out = []
    for l in text.splitlines():
        s = l.strip()
        if not s or s.startswith("#"):
            continue
        # drop a trailing comment: whitespace, '#', whitespace — never a '#' inside a word
        l = re.sub(r"\s#\s.*$", "", l)
        # a path spelled from the repo root is the same path: "$REPO/tools/x.py", ${REPO}/tests/…,
        # "$REPO"/tools/…, "$PWD/tests/…" (the gates cd to the root), $(pwd)/…, $(dirname "$0")/../…
        l = re.sub(r"\$\{?(?:REPO|PWD)\}?\"?/", " ", l)
        l = re.sub(r"\$\(pwd\)\"?/", " ", l)
        l = l.replace(":-", ": ")   # ${VAR:-tests/replays/x.rpl}: the default IS a reference
        l = re.sub(r"\$\(dirname \"?\$0\"?\)/\.\./", " ", l)
        out.append(l)
    return out


def _norm(root, ref):
    cut = CUT_RE.search(ref)
    if cut:
        ref = ref[:cut.start()]
    ref = ref.rstrip(".,;:)}'\"")
    if not ref or ref in ("tests", "tools", "docs", "emu") or ref.endswith("/"):
        return ref if ref.endswith("/") else (ref + "/" if ref else "")
    if os.path.isdir(os.path.join(root, ref)):
        ref += "/"
    return ref


def references(root, gate, rows=None, _seen=None):
    """-> sorted set of repo path references of tests/<gate>.sh: its body, its sourced
    tests/lib/*.sh (transitively) and its registry row's args. Own script excluded."""
    rows = registry_rows(root) if rows is None else rows
    own = f"tests/{gate}.sh"
    refs, seen = set(), set() if _seen is None else _seen

    def scan(rel):
        if rel in seen:
            return
        seen.add(rel)
        p = os.path.join(root, rel)
        if not os.path.exists(p):
            return
        text = open(p, encoding="utf-8", errors="replace").read()
        for l in _body_lines(text):
            for m in REF_RE.findall(l):
                r = _norm(root, m)
                if r and r not in ("tests/", "tools/", "docs/", "emu/"):
                    refs.add(r)
                    if HARNESS_RE.match(r):
                        scan(r)
            sm = SOURCE_RE.match(l)
            if sm:
                refs.add(sm.group(1))
                scan(sm.group(1))

    scan(own)
    args = rows.get(gate, {}).get("args", "")
    for tok in args.split():
        for m in REF_RE.findall(" " + tok):
            r = _norm(root, m)
            if r:
                refs.add(r)
    refs.discard(own)
    for i in IMPLIED:
        refs.discard(i)
    # build outputs are not references (see the docstring)
    return sorted(r for r in refs if not (r.startswith("build/") and not r.startswith("build/manifest")))


# THE WIDENING RULES — what a gate follows BEYOND its text, required of its declaration
# (rule-checker run 2026-09-24-142, Q1/Q4: rules that lived only in the one-shot script
# that wrote the declarations were checked by nothing). A gate that reaches the tree's
# MAME build (through the harness runners or MAME_BIN) follows the emulator's patches and
# setup script; likewise FBNeo; a MiSTer-lane gate follows the core sources; a gate that
# takes or builds a romset follows the manifest; a generated rig follows its generator.
# A gate that runs a bare `mame` from PATH (test_decrypt_oracle, test_patch_prg) reaches
# no binary this tree builds and is not widened — the stock binary is outside the tree.
MAME_HARNESS = ("tools/run_mame.sh", "tools/run_replay_mame.sh", "tools/run_replay_guarded.sh",
                "tools/run_inp_guarded.sh", "tools/run_inp_probe.sh", "tools/tap_latch_reads.sh")
FBNEO_HARNESS = ("tools/run_replay_fbneo.sh", "tools/run_fbneo.sh", "emu/fbneo/")
ROMSET_RE = re.compile(r"%(MERGED|DON|HUI|PYR|STOCK)|build_donovan|build_merged|ensure_merged|"
                       r"build_wide_romset|pack_build|patch_prg|/rompath|BUILD=|build/(m3b|don|hui|pyron|m5)")


def required(root, gate, rows=None, refs=None):
    """-> sorted prefixes the widening rules REQUIRE of tests/<gate>.sh's declaration."""
    rows = registry_rows(root) if rows is None else rows
    refs = references(root, gate, rows) if refs is None else refs
    p = os.path.join(root, f"tests/{gate}.sh")
    text = open(p, encoding="utf-8", errors="replace").read() if os.path.exists(p) else ""
    body = "\n".join(_body_lines(text))
    req = set()
    if any(t in refs for t in MAME_HARNESS) or "MAME_BIN" in body:
        req |= {"emu/mame-patches/", "tools/setup_mame.sh"}
    if any(t in refs for t in FBNEO_HARNESS) or "FBNEO" in body or "fbneo" in body:
        req |= {"emu/fbneo/", "emu/fbneo-patches/", "tools/setup_fbneo.sh"}
    if rows.get(gate, {}).get("lane") == "mister":
        req |= {"emu/jtcores/", "emu/jtcores-patches/", "tests/rtl/", "tools/setup_jtcores.sh"}
    if ROMSET_RE.search(text):
        req.add("build/manifest/")
    if re.search(r"name_moves|replays/naming", text):
        req.add("tools/name_moves.py")
    if "vanilla_join_rig" in text:
        req.add("tools/vanilla_join_rig.py")
    return sorted(req)


PROSE_RE = re.compile(r"\b(\d{2,3}[a-z]?)_[a-z0-9_]+\b|\breplay (\d{2,3}[a-z]?)\b|\breplays? (\d{2,3}[a-z]?) and (\d{2,3}[a-z]?)\b")


def _replay_index(root):
    idx = {}
    for dp, _, fns in os.walk(os.path.join(root, "tests", "replays")):
        for fn in fns:
            if not fn.endswith(".rpl"):
                continue
            rel = os.path.relpath(os.path.join(dp, fn), root)
            stem = fn[:-4]
            idx.setdefault(stem, set()).add(rel)
            num = stem.split("_")[0]
            if re.match(r"^\d+[a-z]?$", num):
                idx.setdefault(num, set()).add(rel)
    return idx


def prose_refs(root, gate, _idx=None):
    """-> {name: set(paths)}: the replays the gate's OWN DESCRIPTION (# WHAT: / # HOW:)
    names by number or stem, resolved to files under tests/replays/. An INDEPENDENT
    extractor: the prose is written by reading the gate, not by the path regex, so a
    path the text extractor cannot see (rule-checker run 2026-09-24-142, Q3) still has
    to be covered when the description names it. A bare number is ambiguous across
    directories (02 = 02_demitri_vs_cpu and judge/02_throw); any resolved path covered
    counts."""
    from gate_descriptions import parse
    idx = _replay_index(root) if _idx is None else _idx
    p = os.path.join(root, f"tests/{gate}.sh")
    if not os.path.exists(p):
        return {}
    fields, _ = parse(open(p, encoding="utf-8", errors="replace").read())
    prose = fields.get("WHAT", "") + " " + fields.get("HOW", "")
    out = {}
    for m in PROSE_RE.finditer(prose):
        for n in m.groups():
            if n and n in idx:
                out[n] = idx[n]
    return out


def covered(ref, prefixes):
    """A directory prefix `x/` also covers the path `x` itself — a submodule pointer
    (emu/fbneo) moves as the bare path in `git diff --name-only`."""
    return any(ref.startswith(p) or ref == p.rstrip("/") for p in prefixes)


def reconcile(root, gate, rows=None, check="all", _idx=None):
    """-> (prefixes, refs, uncovered, problems) for one gate. `uncovered` is a list of
    (class, item): class `text` (a reference of the script, its harness or its args),
    `rule` (a prefix a widening rule requires) or `prose` (a replay the description
    names, none of whose resolved paths is covered). `check` selects the classes."""
    text = open(os.path.join(root, f"tests/{gate}.sh"), encoding="utf-8", errors="replace").read()
    prefixes, problems = declared(text)
    refs = references(root, gate, rows)
    unc = []
    if check in ("all", "text"):
        unc += [("text", r) for r in refs if not covered(r, prefixes)]
    if check in ("all", "rule"):
        unc += [("rule", r) for r in required(root, gate, rows, refs) if not covered(r, prefixes)]
    if check in ("all", "prose"):
        for name, paths in sorted(prose_refs(root, gate, _idx).items()):
            if not any(covered(x, prefixes) for x in paths):
                unc.append(("prose", f"{name}({'|'.join(sorted(paths))})"))
    return prefixes, refs, unc, problems


def census(root):
    """-> [(class, gate, detail)] over the registry's gates: declares / undeclared."""
    out = []
    for g in sorted(registry_rows(root)):
        p = os.path.join(root, f"tests/{g}.sh")
        if not os.path.exists(p):
            out.append(("undeclared", g, "script missing"))
            continue
        toks, problems = declared(open(p, encoding="utf-8", errors="replace").read())
        if problems:
            out.append(("undeclared", g, "; ".join(problems)))
        else:
            out.append(("declares", g, " ".join(toks)))
    return out


def lane_subjects(root, lane):
    """-> (subjects: sorted prefixes, undeclared: [gate]) — the union of a lane's gates'
    declarations plus their scripts and the registry; an undeclared gate is named, not
    guessed around."""
    rows = registry_rows(root)
    subjects, undeclared = set(IMPLIED), []
    for g, r in sorted(rows.items()):
        if r["lane"] != lane:
            continue
        subjects.add(f"tests/{g}.sh")
        p = os.path.join(root, f"tests/{g}.sh")
        if not os.path.exists(p):
            undeclared.append(g)
            continue
        toks, problems = declared(open(p, encoding="utf-8", errors="replace").read())
        if problems:
            undeclared.append(g)
        subjects.update(toks)
    return sorted(subjects), undeclared


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--root", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    ap.add_argument("--reconcile", nargs="?", const="*", metavar="GATE",
                    help="uncovered references per declaring gate (all, or one); exit 1 if any")
    ap.add_argument("--check", default="all", choices=("all", "text", "rule", "prose"),
                    help="which reconciliation class(es) to run (default all)")
    ap.add_argument("--required", metavar="GATE", help="the prefixes the widening rules require of one gate")
    ap.add_argument("--refs", metavar="GATE", help="the references of one gate")
    ap.add_argument("--subjects", metavar="LANE", help="a lane's derived subjects")
    a = ap.parse_args()
    root = a.root
    if a.refs:
        for r in references(root, a.refs):
            print(r)
        return 0
    if a.required:
        for r in required(root, a.required):
            print(r)
        return 0
    if a.subjects:
        subj, und = lane_subjects(root, a.subjects)
        for s in subj:
            print(s)
        if und:
            print(f"UNDECLARED in the {a.subjects} lane: {' '.join(und)}", file=sys.stderr)
            return 1
        return 0
    if a.reconcile:
        rows = registry_rows(root)
        gates = sorted(rows) if a.reconcile == "*" else [a.reconcile]
        bad = 0
        idx = _replay_index(root)
        n_text = n_rule = n_prose = 0
        for g in gates:
            if not os.path.exists(os.path.join(root, f"tests/{g}.sh")):
                continue
            prefixes, refs, unc, problems = reconcile(root, g, rows, a.check, idx)
            if problems:
                continue  # the census reports undeclared gates; reconciliation is for declarers
            n_text += len(refs); n_rule += len(required(root, g, rows, refs)); n_prose += len(prose_refs(root, g, idx))
            if unc:
                bad += 1
                print(f"{g}\tUNCOVERED\t{' '.join(c + ':' + r for c, r in unc)}")
            elif a.reconcile != "*":
                print(f"{g}\tcovered\t{len(refs)} reference(s), {len(required(root, g, rows, refs))} required, "
                      f"{len(prose_refs(root, g, idx))} prose-named replay(s) under {len(prefixes)} prefix(es)")
        print(f"{'FAIL' if bad else 'PASS'}: {bad} declaring gate(s) with a reference outside its declaration "
              f"(check={a.check}: {n_text} text references, {n_rule} rule-required prefixes, {n_prose} prose-named replays)",
              file=sys.stderr)
        return 1 if bad else 0
    rows = census(root)
    for c, g, d in rows:
        print(f"{c}\t{g}\t{d}")
    nd = sum(1 for c, _, _ in rows if c == "declares")
    print(f"{nd} declares, {len(rows) - nd} undeclared, over {len(rows)} registry gates", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
