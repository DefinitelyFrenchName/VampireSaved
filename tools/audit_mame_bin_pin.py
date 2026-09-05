#!/usr/bin/env python3
"""audit_mame_bin_pin.py — every gate that boots `vsavjw` through a MAME
wrapper must PIN the MAME binary (14z-133).

THE CLASS. tools/run_mame.sh (and run_replay_mame.sh / run_replay_guarded.sh
above it) falls back to `mame` on PATH when MAME_BIN is unset. On this
machine that is Homebrew's stock MAME, which answers "Unknown system 'vsavjw'"
and exits — so a leg that boots our WIDE build produces NO DUMPS, and a gate
with a liveness check reports "held the victim on only 0 frames" while a gate
without one may read the empty leg as a verdict. The emulator runner exports
no MAME_BIN (it prints the instruments it found and leaves the environment
alone), so this fires exactly when a gate is run the way a release runs it,
and never in a developer shell that happened to export the variable. The M16
freeze sweep (14z-133) went red on three gates this way; the same trap had
been written into two session openers before and never became a rule.

THE RULE, mechanical: a script under tests/ whose NON-COMMENT text (a) invokes
one of the three MAME wrappers and (b) names `vsavjw` must also carry a real
pin — an assignment `MAME_BIN=` (the `${MAME_BIN:-$HOME/.cache/...}` idiom
118 gates already use, or an inline `MAME_BIN=... tools/run_mame.sh`) or an
`export MAME_BIN`. A `[MAME_BIN=...]` in the Usage line is documentation, not
a pin, and does not count — two of the three 14z-133 reds had exactly that.

Scripts that run only stock sets (`vsavj`, `vsav2`) are OUT of this class:
Homebrew's binary knows those sets, so they run — on a different instrument
from the pinned reference build, which is a separate, recorded observation.

Usage: audit_mame_bin_pin.py <tests-dir | files...>   exit 1 on any UNPINNED
       audit_mame_bin_pin.py --selftest              the must-fire control
"""
import pathlib
import re
import shutil
import sys
import tempfile

WRAP = re.compile(r"run_mame\.sh|run_replay_mame\.sh|run_replay_guarded\.sh")
SETNAME = re.compile(r"\bvsavjw\b")
PIN = re.compile(r"(^|[^A-Za-z0-9_])MAME_BIN=|\bexport\s+MAME_BIN\b", re.M)


def uncomment(path):
    return "\n".join(
        l for l in pathlib.Path(path).read_text(errors="replace").splitlines()
        if not l.lstrip().startswith("#")
    )


def verdict(path):
    """None = out of class; 'pinned' / 'UNPINNED' otherwise."""
    t = uncomment(path)
    if not WRAP.search(t) or not SETNAME.search(t):
        return None
    return "pinned" if PIN.search(t) else "UNPINNED"


def scan(paths):
    files = []
    for p in paths:
        p = pathlib.Path(p)
        files += sorted(p.glob("*.sh")) if p.is_dir() else [p]
    rows = [(f, verdict(f)) for f in files]
    inclass = [(f, v) for f, v in rows if v]
    bad = [f for f, v in inclass if v == "UNPINNED"]
    print(f"  scanned {len(files)} scripts; {len(inclass)} boot vsavjw through a "
          f"MAME wrapper; {len(inclass) - len(bad)} pinned, {len(bad)} UNPINNED")
    for f in bad:
        print(f"  UNPINNED: {f} — boots vsavjw via a MAME wrapper with no MAME_BIN "
              f"assignment/export (Homebrew's mame would answer 'Unknown system')")
    return not bad


def selftest():
    """The control must FIRE: a pinned in-class gate with its pin lines removed
    is reported UNPINNED, and the same file with vsavjw removed drops out of
    the class (so the rule cannot flag stock-set gates)."""
    tests = pathlib.Path(__file__).resolve().parent.parent / "tests"
    src = next((f for f in sorted(tests.glob("*.sh")) if verdict(f) == "pinned"), None)
    if src is None:
        print("  FAIL: no pinned in-class gate exists to build the control from")
        return False
    work = pathlib.Path(tempfile.mkdtemp())
    try:
        lines = src.read_text(errors="replace").splitlines()
        stripped = work / "stripped.sh"
        stripped.write_text("\n".join(l for l in lines if not PIN.search(l)) + "\n")
        noset = work / "noset.sh"
        noset.write_text("\n".join(SETNAME.sub("vsavj", l) for l in lines) + "\n")
        ok = True
        if verdict(stripped) != "UNPINNED":
            print(f"  FAIL: control did not fire — {src.name} minus its pin read as {verdict(stripped)}")
            ok = False
        else:
            print(f"  ok: control fires — {src.name} minus its pin lines is reported UNPINNED")
        if verdict(noset) is not None:
            print(f"  FAIL: {src.name} with vsavjw -> vsavj still classified ({verdict(noset)})")
            ok = False
        else:
            print(f"  ok: the same file booting a stock set is OUT of the class")
        return ok
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args == ["--selftest"]:
        sys.exit(0 if selftest() else 1)
    if not args:
        print(__doc__)
        sys.exit(2)
    sys.exit(0 if scan(args) else 1)
