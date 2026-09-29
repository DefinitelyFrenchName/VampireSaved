#!/usr/bin/env python3
"""battery_reach.py — DOES ANYTHING AN EMULATOR BATTERY RAN READ A FILE DIRTIED DURING THE RUN?
(14z-185, the M21 freeze; promoted from build/rc185/battery_closure.py by the close checklist's step 5.
docs/project/gotchas.md "IS A REACH QUESTION" is the finding: three narrower searches were each caught
by the rule-checker, runs 2026-09-28-398..400.)

Usage:
  python3 tools/battery_reach.py --results build/emu_X/results.tsv [--results ...]
                                 --dirty STATE.md --dirty test_m3a_reproducible --dirty merged1
                                 [--extra-root ../../blackbox-harness] [--driver tests/run_all_emulator.sh]
  --dirty NAME   a dirtied file's name, matched on word boundaries and not followed by a digit
                 (so `merged1` does not match m3b_merged10). Repeatable.
  --results F    a battery's results.tsv; every gate row's tests/<gate>.sh (or .py/.lua) starts the reach.
  --extra-root   a directory outside tools/ and tests/ whose programs a gate can reach (a sibling repo).

REACH, followed transitively from every gate row and the driver:
  (1) PATH form: every slash token written in a file (code OR comment: over-approximates), each suffix tried
      against the repo, tests/ and each EXTRA_ROOT, followed when it names a PROGRAM (.sh .py .lua .pl or an
      extensionless executable; data runs nothing);
  (2) IMPORT form: line-start `import X` / `from X import ...` (incl. `from X import (` spanning lines, a .py
      module or python inline in a shell heredoc), each `;`-separated segment, the body of `python3 -c "..."`,
      `python3 -m X`, and RELATIVE imports. A dotted name resolves to EVERY file under tools/, tests/ or an
      EXTRA_ROOT whose path ends in X/as/path.py or X/as/path/__init__.py, whatever sys.path the program sets.
  NOTHING IS DROPPED: an absolute import that resolves to no such file is classed by its top-level name —
  stdlib or installed, asked of a fresh interpreter run from / — or listed UNRESOLVED. Every sys.path /
  PYTHONPATH line and every variable-rooted path base (${VAR}/...) in the reach is listed, with the
  variable's first assignment.
Then two sets: the over-approximate one, and a STRICT one that ignores comment lines and python docstrings
(a mention there runs nothing). Every line in the reach naming a dirtied file is listed and classed
[comment] or [CODE]; every program under tools/, tests/ and the EXTRA_ROOTs with a [CODE] line is listed
with STRICT / REACHED / not ran, and the chain that reached each reader is printed. The CLASSING of each
[CODE] line (does it open, stat or run the file?) is the reader's to write: the tool finds, it does not judge.

CONTROL (runs first, on a synthetic tree in a temp dir, three finders on it): gate.sh runs tools/a.py by
path, `python3 -m c`, a heredoc `import d`, `python3 -c "import f"` and `$EXT_HOME/bin/run.sh`; a.py
imports pkg.b, extpkg.e and nosuchmod_zz; b imports .h. b, h, c, d, f, ext/extpkg/e.py and ext/bin/run.sh
all read STATE.md. (i) with ext/ as an EXTRA_ROOT all seven are reached and flagged and only nosuchmod_zz
is unresolved; (ii) without it the five in-tree readers are flagged and extpkg.e is LISTED unresolved;
(iii) a path-only finder flags none. Exit 1 when the control is DEAD.
"""
import argparse, os, re, sys, subprocess, tempfile

PATS = {"STATE.md": r"\bSTATE\.md\b"}   # the control's own; main() replaces it with --dirty
REF = re.compile(r"[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)+")
ENVBASE = re.compile(r"\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?/[A-Za-z0-9_.-]")
EXTRA = []   # EXTRA_ROOTs, absolute; set by main and control
FROM = re.compile(r"^\s*from\s+(\.*)([A-Za-z_][\w.]*|)\s+import\b\s*(.*)$")
IMPORT = re.compile(r"^\s*import\s+([A-Za-z_][\w.]*(?:\s+as\s+\w+)?(?:\s*,\s*[A-Za-z_][\w.]*(?:\s+as\s+\w+)?)*)\s*$")
DASHC = re.compile(r"python3?\s+(?:-\w+\s+)*-c\s+([\"'])(.*?)\1")
MOD = re.compile(r"python3?\s+(?:-\w+\s+)*-m\s+([A-Za-z_][\w.]*)")
SYSPATH = re.compile(r"sys\.path\.(?:insert|append)|PYTHONPATH")

def index(root, extra):
    files = []
    for top in ["tools", "tests"] + list(extra):
        base = top if os.path.isabs(top) else os.path.join(root, top)
        for dp, dn, fs in os.walk(base):
            dn[:] = [x for x in dn if x != ".git"]
            for f in fs: files.append(os.path.relpath(os.path.join(dp, f), root))
    return files

def resolve_mod(name, files):
    tail = name.replace(".", "/")
    return [f for f in files if f.endswith("/" + tail + ".py") or f.endswith("/" + tail + "/__init__.py")]

def statements(txt):
    """(dots, module, imported-names) for every import statement found."""
    out = []
    segs = []
    for line in txt.split("\n"):
        segs += line.split(";")
        for m in DASHC.finditer(line): segs += m.group(2).split(";")
    for s in segs:
        s = re.sub(r"\s#.*$", "", s)
        m = FROM.match(s)
        if m:
            names = [x.strip().split(" as ")[0] for x in m.group(3).strip("()\\ ").split(",") if re.match(r"^\s*\w", x)]
            out.append((m.group(1), m.group(2), names)); continue
        m = IMPORT.match(s)
        if m:
            for x in m.group(1).split(","): out.append(("", x.strip().split(" as ")[0].strip(), []))
    for n in MOD.findall(txt): out.append(("", n, []))
    return out

VIA = {}; VIAP = {}; STRICT = [False]
def docstring_lines(path, txt):
    if not path.endswith(".py"): return set()
    import ast
    try: tree = ast.parse(txt)
    except Exception: return set()
    out = set()
    for n in ast.walk(tree):
        if isinstance(n, (ast.Module, ast.FunctionDef, ast.ClassDef, ast.AsyncFunctionDef)) and n.body and isinstance(n.body[0], ast.Expr) \
           and isinstance(getattr(n.body[0], "value", None), ast.Constant) and isinstance(n.body[0].value.value, str):
            out |= set(range(n.body[0].lineno, n.body[0].end_lineno + 1))
    return out
def is_prog(c):
    """a PROGRAM: .sh .py .lua .pl, or an extensionless executable. Data (md, tsv, json, zips, logs) runs nothing and is not followed."""
    b = os.path.basename(c)
    return b.endswith((".sh", ".py", ".lua", ".pl")) or ("." not in b and os.access(c, os.X_OK))
def refs(root, p, files):
    try: txt = open(os.path.join(root, p), encoding="utf-8").read()
    except Exception: return set(), set(), set()
    by_path, by_import, unres = set(), set(), set()
    bases = [root, os.path.join(root, "tests")] + EXTRA
    skip = docstring_lines(p, txt) if STRICT[0] else set()
    if STRICT[0]:
        kept = [("" if (i + 1) in skip or l.strip().startswith(("#", "--")) else l) for i, l in enumerate(txt.split("\n"))]
        txt = "\n".join(kept)
    for ln, line in enumerate(txt.split("\n"), 1):
        for m in REF.finditer(line):
            parts = m.group(0).split("/")
            for k in range(len(parts) - 1):
                sub = "/".join(parts[k:])
                got = None
                for b in bases:
                    c = os.path.join(b, sub)
                    if os.path.isfile(c) and is_prog(c): got = os.path.relpath(c, root); break
                if got:
                    by_path.add(got); VIA.setdefault(got, f"{p}:{ln} path: {line.strip()[:110]}"); VIAP.setdefault(got, p); break
    for dots, mod, names in statements(txt):
        if dots:   # relative: resolve against the importing file's own directory
            base = os.path.dirname(p)
            for _ in range(len(dots) - 1): base = os.path.dirname(base)
            stem = os.path.join(base, *mod.split(".")) if mod else base
            for cand in [stem + ".py", os.path.join(stem, "__init__.py")] + [os.path.join(stem, n + ".py") for n in names]:
                if os.path.isfile(os.path.join(root, cand)):
                    c = os.path.normpath(cand); by_import.add(c); VIA.setdefault(c, f"{p} import .{mod}"); VIAP.setdefault(c, p)
            continue
        hit = resolve_mod(mod, files)
        for n in names: hit += resolve_mod(mod + "." + n, files)
        if hit:
            by_import |= set(hit)
            for h in hit: VIA.setdefault(h, f"{p} import {mod}"); VIAP.setdefault(h, p)
        else: unres.add(mod)
    return by_path, by_import, unres

def closure(root, starts, files, follow_imports=True):
    seen, todo, unres = set(), list(starts), {}
    while todo:
        p = todo.pop()
        if p in seen or not os.path.isfile(os.path.join(root, p)): continue
        seen.add(p)
        a, b, u = refs(root, p, files)
        for m in u: unres.setdefault(m, set()).add(p)
        nxt = a | (b if follow_imports else set())
        todo += sorted((x for x in nxt if x not in seen), reverse=True)   # deterministic: the first reference recorded is the same on every run (set order is hash-seeded)
    return seen, unres

def classify(tops):
    """top-level module -> stdlib | installed | UNRESOLVED, asked of a fresh interpreter run from / (no repo on its path)."""
    prog = ("import importlib.util, sys, sysconfig\n"
            "std = sysconfig.get_paths()['stdlib']\n"
            "for n in sys.argv[1:]:\n"
            "    try: s = importlib.util.find_spec(n)\n"
            "    except Exception: s = None\n"
            "    o = (s.origin or '') if s else ''\n"
            "    c = 'UNRESOLVED' if s is None else ('stdlib' if (o in ('built-in', 'frozen') or (o.startswith(std) and 'site-packages' not in o) or n in sys.builtin_module_names) else ('installed' if 'site-packages' in o else 'OTHER:' + o))\n"
            "    print(n, c)\n")
    r = subprocess.run([sys.executable, "-c", prog] + sorted(tops), cwd="/", capture_output=True, text=True,
                       env={k: v for k, v in os.environ.items() if k != "PYTHONPATH"})
    return dict(l.split(" ", 1) for l in r.stdout.split("\n") if l.strip())

def hits(root, files_set):
    out = []
    for p in sorted(files_set):
        try: lines = open(os.path.join(root, p), encoding="utf-8").read().split("\n")
        except Exception: continue
        for i, l in enumerate(lines, 1):
            for k, rx in PATS.items():
                if re.search(rx, l):
                    s = l.strip()
                    out.append(("comment" if s.startswith(("#", "--")) else "CODE", k, p, i, s[:150]))
    return out

def control():
    d = tempfile.mkdtemp(prefix="closure_ctl_")
    def w(rel, t):
        os.makedirs(os.path.dirname(os.path.join(d, rel)), exist_ok=True); open(os.path.join(d, rel), "w").write(t)
    rd = "x = open('STATE.md').read()\n"
    w("tests/gate.sh", "#!/bin/sh\npython3 tools/a.py\npython3 -m c\npython3 - <<'EOF'\nimport d\nEOF\npython3 -c \"import sys; import f\"\nsh \"$EXT_HOME/bin/run.sh\"\n")
    w("ext/bin/run.sh", "cat STATE.md\n")
    w("tools/a.py", "import sys\nsys.path.insert(0, '../ext')\nfrom pkg import b\nimport extpkg.e\nimport nosuchmod_zz\n")
    w("tools/lib/pkg/__init__.py", ""); w("tools/lib/pkg/b.py", "from .h import y\n" + rd); w("tools/lib/pkg/h.py", rd)
    w("tools/c.py", rd); w("tools/lib/d.py", rd); w("tools/lib/f.py", rd)
    w("ext/extpkg/__init__.py", ""); w("ext/extpkg/e.py", rd)
    intree = {"tools/lib/pkg/b.py", "tools/lib/pkg/h.py", "tools/c.py", "tools/lib/d.py", "tools/lib/f.py"}
    ok = True
    for label, extra, follow, want, want_unres in (
            ("(i) v3 + ext/ as EXTRA_ROOT", [os.path.join(d, "ext")], True, intree | {"ext/extpkg/e.py", "ext/bin/run.sh"}, {"nosuchmod_zz"}),
            ("(ii) v3, tools/tests only", [], True, intree, {"extpkg.e", "nosuchmod_zz"}),
            ("(iii) paths only (the run 399 finder)", [], False, set(), None)):
        EXTRA[:] = extra; VIA.clear()
        files = index(d, extra)
        s, unres = closure(d, ["tests/gate.sh"], files, follow_imports=follow)
        if not follow:   # (iii) the run 399 finder: in-tree paths only
            EXTRA[:] = []
        got = {h[2] for h in hits(d, s) if h[0] == "CODE" and h[1] == "STATE.md"}
        u = set(k for k, v in unres.items()) - {"sys"}
        good = got == want and (want_unres is None or u == want_unres)
        ok &= good
        print(f"CONTROL {label}: readers flagged {sorted(got)}; unresolved (bar stdlib sys) {sorted(u) if want_unres is not None else '-'} — "
              f"{'as expected' if good else 'UNEXPECTED, want ' + str(sorted(want)) + ' / ' + str(want_unres)}")
    print("CONTROL " + ("FIRED: an import and a variable-rooted path outside tools/ and tests/ are reached with their root given; without it the import "
                        "is LISTED unresolved and the path's base variable ($EXT_HOME) is listed among the external bases; the path-only finder flags none" if ok else "DEAD"))
    EXTRA[:] = []; VIA.clear()
    return ok

if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="does anything a battery ran read a dirtied file?")
    ap.add_argument("--results", action="append", required=True)
    ap.add_argument("--dirty", action="append", required=True)
    ap.add_argument("--extra-root", action="append", default=[])
    ap.add_argument("--driver", default="tests/run_all_emulator.sh")
    a = ap.parse_args()
    if not control(): sys.exit(1)
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    PATS.clear(); PATS.update({n: r"\b" + re.escape(n) + r"\b(?![0-9])" for n in a.dirty})
    extra = [os.path.abspath(x) for x in a.extra_root]
    EXTRA[:] = extra
    files = index(root, extra)
    gates = []
    for f in a.results:
        for l in open(os.path.join(root, f)).read().split("\n")[1:]:
            if l.strip(): gates.append(l.split("\t")[0])
    starts = []
    for g in gates:
        s = next((c for c in (f"tests/{g}.sh", f"tests/{g}.py", f"tests/{g}.lua") if os.path.isfile(os.path.join(root, c))), None)
        if s is None: print(f"NO SCRIPT for gate {g}"); sys.exit(1)
        starts.append(s)
    starts.append(a.driver)
    ran, unres = closure(root, starts, files)
    via = dict(VIA); VIAP_ALL = dict(VIAP)
    ran_paths, _ = closure(root, starts, files, follow_imports=False)
    print(f"EXTRA_ROOTS: {extra or 'none'}")
    print(f"gates: {len(gates)} (every one's script found) + the driver {a.driver}; dirtied: {' '.join(a.dirty)}")
    print(f"ran set (paths + imports, transitive): {len(ran)} files; by paths alone: {len(ran_paths)}; reached ONLY through an import: {len(ran - ran_paths)}")
    for p in sorted(ran - ran_paths): print("   import-only: " + p)
    outside = sorted(p for p in ran if not p.startswith(('tools/', 'tests/')))
    print(f"   ran-set files outside tools/ and tests/ ({len(outside)}), each with the reference that first reached it:")
    for p in outside: print(f"      {p}  <- {via.get(p, '?')}")
    for p in ("tests/test_bbh_fidelity.sh", "tests/run_all_static.sh"):
        if p in ran: print(f"   reached-via {p} <- {via.get(p, '?')}")
    envb = {}
    for p in sorted(ran):
        try: txt = open(os.path.join(root, p), encoding="utf-8").read()
        except Exception: continue
        for m in ENVBASE.finditer(txt): envb.setdefault(m.group(1), set()).add(p)
    print(f"== variable-rooted path bases in the ran set (${{VAR}}/...): {len(envb)} variables — every directory a program reaches through a variable")
    assign = {}
    for p in sorted(ran):
        try: L = open(os.path.join(root, p), encoding="utf-8").read().split("\n")
        except Exception: continue
        for i, l in enumerate(L, 1):
            for m in re.finditer(r"(?:^|[\s;(])(?:export\s+|local\s+)?([A-Za-z_][A-Za-z0-9_]*)=(\S+)", l):
                if m.group(1) in envb and m.group(1) not in assign: assign[m.group(1)] = f"{p}:{i}: {m.group(2)[:90]}"
            for m in re.finditer(r"\bfor\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\b", l):
                if m.group(1) in envb and m.group(1) not in assign: assign[m.group(1)] = f"{p}:{i}: (loop variable) {l.strip()[:80]}"
            for m in re.finditer(r"\bread\s+(?:-r\s+)?([A-Za-z_][A-Za-z0-9_ ]*)", l):
                for v in m.group(1).split():
                    if v in envb and v not in assign: assign[v] = f"{p}:{i}: (read) {l.strip()[:80]}"
    for k in sorted(envb):
        print(f"   ${k}  used in {len(envb[k])} file(s); first assignment: {assign.get(k, 'NONE FOUND in the ran set (environment, positional or caller-set)')}")
    tops = {m.split(".")[0] for m in unres}
    cls = classify(tops)
    byc = {}
    for t in sorted(tops): byc.setdefault(cls.get(t, "UNRESOLVED"), []).append(t)
    print(f"== absolute imports in the ran set that resolve to no file under tools/, tests/ or an EXTRA_ROOT: {len(unres)} names, {len(tops)} top-level")
    for c in sorted(byc): print(f"   {c} ({len(byc[c])}): {' '.join(byc[c])}")
    for t in byc.get("UNRESOLVED", []) + [x for c in byc if c.startswith("OTHER") for x in byc[c]]:
        for m in sorted(k for k in unres if k.split(".")[0] == t):
            print(f"   UNRESOLVED {m}: imported by {sorted(unres[m])[:6]}")
    sp = []
    for p in sorted(ran):
        try: L = open(os.path.join(root, p), encoding="utf-8").read().split("\n")
        except Exception: continue
        for i, l in enumerate(L, 1):
            if SYSPATH.search(l) and not l.strip().startswith(("#", "--")): sp.append(f"   syspath: {p}:{i}: {l.strip()[:150]}")
    print(f"== sys.path / PYTHONPATH lines in the ran set: {len(sp)}")
    for x in sp: print(x)
    dyn = []
    for p in sorted(ran):
        try: L = open(os.path.join(root, p), encoding="utf-8").read().split("\n")
        except Exception: continue
        for i, l in enumerate(L, 1):
            s = l.strip()
            if s.startswith(("#", "--")): continue
            if re.search(r"\bimportlib\b|__import__\(|\brunpy\b|\bexec\(|\bspec_from_file_location\b", l): dyn.append(f"   dynamic: {p}:{i}: {s[:140]}")
    print(f"== dynamic-load sites in the ran set (importlib, __import__, runpy, exec, spec_from_file_location): {len(dyn)}")
    for x in dyn: print(x)
    H = hits(root, ran)
    print(f"== every line in the ran set naming a dirtied file ({len(H)}), classed:")
    for c, k, p, i, s in H: print(f"   [{c}] {k}: {p}:{i}: {s}")
    progs = [f for f in files if f.endswith((".sh", ".py", ".lua", ".pl")) or (os.access(os.path.join(root, f), os.X_OK) and "." not in os.path.basename(f))]
    allH = hits(root, set(progs))
    code_files = sorted({(h[2]) for h in allH if h[0] == "CODE"})
    VIA.clear(); VIAP.clear(); STRICT[0] = True
    strict, _ = closure(root, starts, files)
    via_s, viap_s = dict(VIA), dict(VIAP); STRICT[0] = False
    print(f"== STRICT ran set (the same reach, but no reference on a comment line or inside a python docstring is followed): {len(strict)} files")
    print(f"   in the over-approximate set only: {len(ran - strict)}")
    print(f"== every PROGRAM under tools/, tests/ and the EXTRA_ROOTs ({len(progs)} of {len(files)} files: .sh .py .lua .pl or an extensionless executable)")
    print(f"   with a [CODE] line naming a dirtied file ({len(code_files)}), and whether the battery ran it:")
    print("   (REACHED = in the over-approximate set; STRICT = also reached with comment and docstring mentions ignored)")
    for p in code_files:
        ks = sorted({h[1] for h in allH if h[2] == p and h[0] == "CODE"})
        tag = "STRICT " if p in strict else ("REACHED" if p in ran else "not ran")
        print(f"   {tag}  {p}  ({', '.join(ks)})")
    def chain(p, via, viap):
        out, seen = [], set()
        while p in viap and p not in seen:
            seen.add(p); out.append(f"{p}  <- {via.get(p, '?')}"); p = viap[p]
        out.append(f"{p}  (a gate script or the driver)")
        return out
    print("== the chain that reached each REACHED or STRICT reader (child <- the reference in its parent), strict chain where there is one:")
    for p in code_files:
        if p in strict: c, lab = chain(p, via_s, viap_s), "STRICT"
        elif p in ran: c, lab = chain(p, via, VIAP_ALL), "REACHED only"
        else: continue
        print(f"   [{lab}] {p}")
        for x in c: print(f"        {x}")
