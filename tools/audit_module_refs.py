#!/usr/bin/env python3
"""audit_module_refs.py [--plant] [--json]

DOES EVERY CROSS-MODULE NAME A TOOL OR GATE REFERENCES STILL EXIST? — the static
census behind GitHub #171's first failure shape.

WHY (14z-174, the M19 release tier): `tools/vanilla_join_rig.py` referenced
`name_moves.PROLOGUE`, deleted at `e01ae8de` (14z-165) when the rigs' P2 became
per-tenant and nobody updated the caller. Three emulator-tier gates died at 0 s on
`AttributeError`, two more measured 0 rows and compared an empty table, and every
session close in between read GREEN — the emulator tier only runs at a freeze or a
release, and no static check resolved the name. This tool resolves it, in the
static tier, on every session run: for every `import <tool>` / `from <tool> import`
of a module under `tools/`, and every `<alias>.<NAME>` reference to it, NAME must be
defined at that module's top level (functions, classes, assignments, imports — read
by AST, never by importing, so a tool with side effects at import is never run).

    python3 tools/audit_module_refs.py            # the census; exit 1 on any unresolved
    python3 tools/audit_module_refs.py --plant    # the must-fire control: PARSES the historical
                                                  # caller (tools/vanilla_join_rig.py as it was at
                                                  # e01ae8de^, `name_moves.PROLOGUE` at its line 110,
                                                  # read with `git show`) through the same extractor
                                                  # as the census, and must report that reference
                                                  # unresolved — so the control exercises the AST
                                                  # walk, not only the resolve step (a first form
                                                  # appended the tuple after parsing; rule-checker
                                                  # run 2026-09-24-141 Q4 caught it)
    python3 tools/audit_module_refs.py --plant-empty  # the second control: a census over NO files
                                                  # must FAIL its floor (0 references is an empty
                                                  # measurement, never a pass — #171 shape 1b)
    python3 tools/audit_module_refs.py --floor N  # the fewest references a PASS may carry
                                                  # (default 1; the gate pins the frozen count)

WHAT IT DOES NOT SEE (stated so the census is not read as stronger than it is):
dynamic attribute access (`getattr`, `__dict__`), names created by `exec`, names a
module defines only inside a function, and references from SHELL gates to python
symbols (a gate calling `python3 -c 'import x; x.Y'` is a string to this tool). A
module-level name defined under `if`/`try` at top level IS seen.
"""
import argparse, ast, glob, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
# The historical case: the caller as it stood the moment the constant was deleted (the
# parent of e01ae8de, 14z-165). `references()` must find `name_moves.PROLOGUE` in it.
PLANT_REV = "e01ae8de^:tools/vanilla_join_rig.py"
PLANT_REF = ("name_moves", "PROLOGUE")


def toplevel_names(path):
    names = set()
    try:
        tree = ast.parse(open(path, encoding="utf-8").read(), path)
    except SyntaxError as e:
        return names, f"SYNTAX {path}: {e}"
    def add_targets(node):
        for t in getattr(node, "targets", [getattr(node, "target", None)]):
            if t is None: continue
            for x in ast.walk(t):
                if isinstance(x, ast.Name): names.add(x.id)
    def visit_block(body):
        for n in body:
            if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)): names.add(n.name)
            elif isinstance(n, (ast.Assign, ast.AnnAssign, ast.AugAssign)): add_targets(n)
            elif isinstance(n, (ast.Import, ast.ImportFrom)):
                for a in n.names: names.add((a.asname or a.name).split(".")[0])
            elif isinstance(n, (ast.If, ast.Try, ast.With, ast.For, ast.While)):
                for attr in ("body", "orelse", "finalbody"):
                    visit_block(getattr(n, attr, []) or [])
                for h in getattr(n, "handlers", []) or []: visit_block(h.body)
    visit_block(tree.body)
    return names, None


def references(path, local):
    """(module, attr, lineno) for every reference into a local tools module."""
    out = []
    try:
        tree = ast.parse(open(path, encoding="utf-8").read(), path)
    except SyntaxError as e:
        return out, f"SYNTAX {path}: {e}"
    aliases = {}
    for n in ast.walk(tree):
        if isinstance(n, ast.Import):
            for a in n.names:
                if a.name in local: aliases[a.asname or a.name] = a.name
        elif isinstance(n, ast.ImportFrom) and n.module in local and n.level == 0:
            for a in n.names:
                if a.name != "*": out.append((n.module, a.name, n.lineno))
    # An alias is the MODULE only where nothing else binds that name: a function
    # whose parameter, loop variable or assignment is `pp` refers to its own `pp`,
    # not to `import projectile_params as pp` (charmap_gen.py:191 was such a false
    # positive on the first run). Module-level rebinding by a non-import shadows it
    # for the whole file.
    def bound_names(fn):
        names = {a.arg for a in fn.args.args + fn.args.kwonlyargs + fn.args.posonlyargs}
        for extra in (fn.args.vararg, fn.args.kwarg):
            if extra: names.add(extra.arg)
        for x in ast.walk(fn):
            if isinstance(x, (ast.Assign, ast.AnnAssign, ast.AugAssign, ast.For, ast.comprehension, ast.With)):
                targets = getattr(x, "targets", None) or [getattr(x, "target", None)]
                if isinstance(x, ast.With): targets = [i.optional_vars for i in x.items if i.optional_vars]
                for t in targets:
                    if t is None: continue
                    for y in ast.walk(t):
                        if isinstance(y, ast.Name): names.add(y.id)
            elif isinstance(x, ast.ExceptHandler) and x.name: names.add(x.name)
        return names
    module_rebound = set()
    for n in tree.body:
        if isinstance(n, (ast.Assign, ast.AnnAssign, ast.AugAssign, ast.For)):
            targets = getattr(n, "targets", None) or [getattr(n, "target", None)]
            for t in targets:
                for y in ast.walk(t):
                    if isinstance(y, ast.Name): module_rebound.add(y.id)
    def visit(node, shadow):
        for child in ast.iter_child_nodes(node):
            if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda)):
                inner = shadow | (bound_names(child) if not isinstance(child, ast.Lambda) else {a.arg for a in child.args.args})
                visit(child, inner)
            else:
                if isinstance(child, ast.Attribute) and isinstance(child.value, ast.Name) \
                        and child.value.id in aliases and child.value.id not in shadow:
                    out.append((aliases[child.value.id], child.attr, child.lineno))
                visit(child, shadow)
    visit(tree, set(module_rebound))
    return out, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--plant", action="store_true",
                    help="must-fire control: parse the historical caller (git show %s) through the extractor" % PLANT_REV)
    ap.add_argument("--plant-empty", action="store_true", help="must-fire control: a census over no files must fail the floor")
    ap.add_argument("--floor", type=int, default=1, help="the fewest references a PASS may carry (default 1)")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()
    os.chdir(REPO)
    local = {os.path.splitext(os.path.basename(p))[0]: p for p in glob.glob("tools/*.py")}
    files = sorted(set(glob.glob("tools/**/*.py", recursive=True) + glob.glob("tests/**/*.py", recursive=True)))
    if a.plant_empty:
        files = []
    defs, errors = {}, []
    for m, p in local.items():
        defs[m], err = toplevel_names(p)
        if err: errors.append(err)
    refs = []  # (file, module, attr, lineno)
    for f in files:
        rs, err = references(f, local)
        if err: errors.append(err)
        refs += [(f, m, at, ln) for (m, at, ln) in rs]
    if a.plant:
        # The control PARSES the historical caller through the same extractor: a plant
        # appended after parsing would prove the resolve step and nothing about the walk.
        import subprocess, tempfile
        src = subprocess.run(["git", "-C", REPO, "show", PLANT_REV], capture_output=True, text=True)
        if src.returncode != 0 or PLANT_REF[1] not in src.stdout:
            print(f"CONTROL DEAD: planted-prologue — could not read {PLANT_REV} with the reference in it")
            return 1
        with tempfile.NamedTemporaryFile("w", suffix="_plant_vanilla_join_rig.py", delete=False) as tf:
            tf.write(src.stdout); plant_path = tf.name
        try:
            rs, err = references(plant_path, local)
        finally:
            os.unlink(plant_path)
        if err: errors.append(err)
        refs += [(f"<plant {PLANT_REV}>", m, at, ln) for (m, at, ln) in rs]
    unresolved = sorted(set((f, m, at, ln) for (f, m, at, ln) in refs if at not in defs.get(m, set())))
    pairs = len(set((f, m) for f, m, _, _ in refs))
    summary = {"files": len(files), "modules": len(local), "refs": len(refs), "pairs": pairs,
               "unresolved": len(unresolved), "errors": errors}
    if a.json:
        print(json.dumps({**summary, "unresolved_refs": unresolved}, indent=1))
    else:
        print(f"== module references: {len(files)} python files, {len(local)} tools modules, "
              f"{len(refs)} references over {pairs} (file, module) pairs ==")
        for e in errors: print(f"  {e}")
        for f, m, at, ln in unresolved:
            print(f"  UNRESOLVED {f}:{ln}  {m}.{at}")
    if a.plant:
        hit = [u for u in unresolved if u[1:3] == PLANT_REF and u[0].startswith("<plant ")]
        if hit:
            print(f"CONTROL FIRED: planted-prologue — the extractor found name_moves.PROLOGUE at line {hit[0][3]} "
                  f"of {PLANT_REV} and it is reported unresolved")
            print("FAIL (planted): the control must fail"); return 1
        print("CONTROL DEAD: planted-prologue — the historical reference was NOT extracted or NOT reported"); return 1
    if a.plant_empty:
        if len(refs) < a.floor:
            print(f"CONTROL FIRED: empty-census — {len(refs)} reference(s) over {len(files)} files is below the floor of {a.floor}")
            print("FAIL (planted): the control must fail"); return 1
        print("CONTROL DEAD: empty-census — an empty census passed the floor"); return 1
    if errors or unresolved:
        print(f"FAIL: {len(unresolved)} unresolved reference(s), {len(errors)} parse error(s)"); return 1
    if len(refs) < a.floor:
        print(f"FAIL: {len(refs)} reference(s) is below the floor of {a.floor} — an empty measurement is not a pass"); return 1
    print(f"PASS: every one of {len(refs)} cross-module references resolves (floor {a.floor})"); return 0


if __name__ == "__main__":
    sys.exit(main())
