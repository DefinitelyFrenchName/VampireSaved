#!/bin/sh
# test_shell_portability.sh — a `#!/bin/sh` script must actually be POSIX sh
# (14z-90, GitHub issue #15).
#
# WHY. tools/build_donovan.sh carried `#!/bin/sh` and `set -o pipefail`. Under
# dash — /bin/sh on Debian, Ubuntu and WSL2 — it died at line 12 before
# touching anything:
#     $ /bin/dash tools/build_donovan.sh
#     tools/build_donovan.sh: 12: set: Illegal option -o pipefail
# On macOS /bin/sh is bash in sh mode, which accepts it, so the whole tree
# looked portable on the only machine that ever ran it. HANDOFF.md compounded
# this by ranking Linux "Best destination … every tests/*.sh runs unchanged",
# written three days AFTER pipefail landed and never validated.
#
# The fix was NOT to delete line 12 — that silently reinstates the 14z-10
# stale-tiles trap over five real `| tail -N` pipelines — and NOT to migrate
# 155 shebangs. It was to declare the dependency on the ONE script that has
# it. This gate keeps that honest in both directions:
#   * a `#!/bin/sh` script must contain no shell-context bashism;
#   * a script that needs bash must SAY so in its shebang.
#
# HEREDOC BODIES ARE EXCLUDED, and that matters: these scripts embed Python
# and TOML, and `[[table]]` in a TOML heredoc is not a bash test. A census
# that does not strip heredocs reports ~16 false positives and was the reason
# the filed issue over-counted. `dash -n` is NOT a substitute either — it is a
# parser check, and it returns 0 on the very file that was proven dead.
#
# Usage: tests/test_shell_portability.sh   (no ROMs, no emulator, ~1s)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

python3 - <<'PY'
import re, subprocess, sys

files = subprocess.run(["git", "ls-files", "*.sh"], capture_output=True,
                       text=True).stdout.split()
# Shell-context bashisms that dash rejects or silently mis-evaluates.
BASHISM = [
    (re.compile(r"^\s*set\s+-o\s+pipefail"), "set -o pipefail"),
    (re.compile(r"(^|[;&|(\s])\[\[[\s]"),    "[[ ]] test"),
    (re.compile(r"^\s*\w+=\("),              "bash array"),
    # command position only — "(source build)" inside a message is not a
    # bashism, and matching it produced four false positives on first run.
    (re.compile(r"^\s*source\s"),            "`source` (use `.`)"),
    (re.compile(r"<<<"),                     "here-string"),
]
HEREDOC = re.compile(r"<<-?\s*'?\"?([A-Za-z_][A-Za-z0-9_]*)'?\"?")

bad, needbash = [], []
for f in files:
    try:
        lines = open(f, encoding="utf-8", errors="replace").read().split("\n")
    except OSError:
        continue
    shebang = lines[0] if lines else ""
    is_sh = shebang.strip() == "#!/bin/sh"
    # strip heredoc bodies before scanning
    body, term = [], None
    for ln in lines:
        if term is not None:
            if ln.strip() == term:
                term = None
            continue
        m = HEREDOC.search(ln)
        if m:
            term = m.group(1)
            body.append(ln[:m.start()])
            continue
        body.append(ln)
    hits = []
    for i, ln in enumerate(body, 1):
        if ln.lstrip().startswith("#"):
            continue
        for rx, name in BASHISM:
            if rx.search(ln):
                hits.append((i, name, ln.strip()[:60]))
    if hits and is_sh:
        bad.append((f, hits))
    elif hits:
        needbash.append((f, [h[1] for h in hits]))

for f, hits in needbash:
    print(f"  ok: {f} declares bash and uses {sorted(set(hits))}")
if not needbash:
    print("  ok: no script declares bash (none needs it)")

if bad:
    print("\nFAIL: these scripts say #!/bin/sh but use bash-only constructs.")
    print("      They abort or mis-evaluate under dash (Debian/Ubuntu/WSL2).")
    for f, hits in bad:
        for ln, name, txt in hits:
            print(f"  {f}:{ln}  {name}   {txt}")
    print("\n  Fix by making the construct POSIX, or by declaring")
    print("  #!/usr/bin/env bash if the construct is load-bearing.")
    sys.exit(1)
print(f"  ok: all {len(files)} tracked .sh files are honest about their shell")
PY

echo "PASS: shell portability (no #!/bin/sh script uses a bash-only construct)"
