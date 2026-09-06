#!/bin/sh
# test_demand_after_trap.sh — no gate carries a `${VAR:?msg}` DEMAND after its
# EXIT trap (14z-134). ci_portable: no ROM, no build dir, no emulator, ~1 s.
#
# WHY. On macOS bash 3.2 — /bin/sh AND /bin/bash — a parameter-expansion
# abort (`${VAR:?}` on an unset VAR) exits the shell with status 0 once an
# EXIT trap is armed; without the trap it exits 1, and a trap written to
# preserve `$?` still returns 0 because `$?` is already 0 when the trap runs.
# The M16 release run (14z-134) recorded `test_mister_obj_oracle`, a
# 65-minute Verilator gate, as `PASS 0s`: it died at
# `: "${JTSIM_SCRATCH:?…}"` eight lines after `trap 'rm -rf "$W"' EXIT`, and
# the runner's exit-status-first classifier read the 0. docs/project/gotchas.md
# has the measurement. The runner now also fails a log carrying the shell's
# `<script>.sh: line N: NAME: message` with exit 0 (test_emulator_runner §12);
# this gate removes the cause: a demand is written as an explicit test —
# `[ -n "${X:-}" ] || { echo "FAIL: set X"; exit 1; }` — once a trap is armed.
# Demands BEFORE the trap (the usual top-of-file `${ROMDIR:?set ROMDIR}`, ~200
# gates) exit 1 correctly and are allowed.
#
# SCOPE: every tests/*.sh and tests/lib/*.sh. A `${VAR:?…}` inside a heredoc
# that writes a STUB SCRIPT runs in the stub's own shell (no trap) and is
# allowed — the scanner skips heredoc bodies.
#
# MUST-FIRE CONTROL: a synthetic script with a demand after its trap is
# reported; the same script with the demand before the trap is not.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

scan() {  # scan <dir> — prints "file:line: text" for every demand after the first EXIT trap
python3 - "$1" <<'EOF'
import re, sys, pathlib
root = pathlib.Path(sys.argv[1])
TRAP = re.compile(r"(^|[;&|]\s*)trap\b.*\bEXIT\b")   # `W="$(mktemp -d)"; trap … EXIT` is the common one-line form
DEMAND = re.compile(r"\$\{[A-Za-z_][A-Za-z0-9_]*:\?")
HEREDOC = re.compile(r"<<-?\s*['\"]?(\w+)['\"]?")
hits = 0
for f in sorted(list(root.glob("*.sh")) + list((root / "lib").glob("*.sh"))):
    if f.name == "test_demand_after_trap.sh":
        continue   # this gate's own fixtures carry the literal pattern
    trap_line = None; heredoc_end = None
    for n, line in enumerate(f.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if heredoc_end is not None:
            if line.strip() == heredoc_end:
                heredoc_end = None
            continue
        m = HEREDOC.search(line)
        if m and not line.lstrip().startswith("#"):
            heredoc_end = m.group(1)
        if trap_line is None and TRAP.search(line) and not line.lstrip().startswith("#"):
            trap_line = n
            continue
        if trap_line is not None and DEMAND.search(line) and not line.lstrip().startswith("#"):
            print(f"{f.relative_to(root)}:{n}: {line.strip()[:100]}")
            hits += 1
sys.exit(1 if hits else 0)
EOF
}

echo "== test_demand_after_trap: no \${VAR:?} demand after an EXIT trap =="
if out="$(scan tests)"; then
    ok "no gate carries a demand after its EXIT trap"
else
    bad "demand(s) after an EXIT trap — write them as explicit tests:"; printf '%s\n' "$out" | sed 's/^/        /'
fi

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
mkdir -p "$W/a/lib" "$W/b/lib"
printf '#!/bin/sh\nset -eu\nW=$(mktemp -d); trap '"'"'rm -rf "$W"'"'"' EXIT\n: "${FOO:?set FOO}"\n' > "$W/a/g.sh"
printf '#!/bin/sh\nset -eu\n: "${FOO:?set FOO}"\nW=$(mktemp -d); trap '"'"'rm -rf "$W"'"'"' EXIT\ncat <<EOS\nstub ${BAR:?} in a heredoc is fine\nEOS\n' > "$W/b/g.sh"
if scan "$W/a" >/dev/null; then bad "control: a demand AFTER the trap was not reported"; else ok "control fires: a demand after the trap is reported"; fi
if scan "$W/b" >/dev/null; then ok "control: a demand BEFORE the trap, and one inside a heredoc, are allowed"; else bad "control: the allowed shapes were reported"; fi

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
