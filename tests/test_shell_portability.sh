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
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-90 (issue #15): every #!/bin/sh script must be POSIX sh. Strips
#   heredoc bodies first (these scripts embed Python and TOML; an unstripped
#   census reports ~16 false [[table]] hits). A script that needs bash must
#   say so in its shebang — today exactly one does. No ROMs, no emulator, ~1s
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

# ---------------------------------------------------------------------
# THE ASSIGNMENT-ONLY CONTINUATION CHAIN (added 14z-92, GitHub #84).
# A continuation whose whole logical line is VAR=... assignments and NO
# COMMAND sets shell variables that never enter any child's environment.
# tests/test_pyron_ladder.sh had exactly this shape, so build_donovan.sh —
# a separate process — never saw the tenant selection and fell back to its
# Donovan defaults. THE PYRON LADDER BUILT DONOVAN AT EVERY STAGE and
# stayed green, because a gate that validates the wrong thing still
# validates something.
#
# Deliberately NOT the naive "assignment line followed by an assignment
# line": `VAR=a \` + `VAR=b command` is the normal correct idiom and must
# not be flagged. The test is whether the joined chain EVER REACHES A
# COMMAND. A multi-line single value (CORPUS="a b c ...") is also
# assignment-only and legitimate, so a chain assigning exactly ONE
# variable is exempt.
import re as _re
_ASSIGN = _re.compile(r"[A-Za-z_][A-Za-z0-9_]*=(?:\"[^\"]*\"|'[^']*'|[^\s]*)\s*")
_off = []
for _f in files:
    _lines = open(_f).read().split("\n")
    _i = 0
    while _i < len(_lines):
        if _lines[_i].rstrip().endswith("\\"):
            _start, _parts = _i, []
            while _i < len(_lines) and _lines[_i].rstrip().endswith("\\"):
                _parts.append(_lines[_i].rstrip()[:-1]); _i += 1
            if _i < len(_lines):
                _parts.append(_lines[_i])
            _log = " ".join(x.strip() for x in _parts).strip()
            _rest, _n = _log, 0
            while True:
                _m = _ASSIGN.match(_rest)
                if not _m:
                    break
                _rest = _rest[_m.end():]; _n += 1
            if _n > 1 and not _rest.strip():
                _off.append((_f, _start + 1, _log[:90]))
        _i += 1
if _off:
    print("\nFAIL: continuation chains that assign several variables and")
    print("      never reach a command. Those assignments are LOCAL and")
    print("      do not reach any child process (GitHub #84).")
    for _f, _ln, _t in _off:
        print(f"  {_f}:{_ln}  {_t}")
    sys.exit(1)
print("  ok: no multi-variable continuation chain ends without a command")

# VERDICT CONTROL on the detector just used. It must FIRE on the real
# pre-fix #84 shape and stay SILENT on the two legitimate idioms it
# resembles, or the clean sweep above means nothing.
def _scan(text):
    ls, out, i = text.split("\n"), [], 0
    while i < len(ls):
        if ls[i].rstrip().endswith("\\"):
            parts = []
            while i < len(ls) and ls[i].rstrip().endswith("\\"):
                parts.append(ls[i].rstrip()[:-1]); i += 1
            if i < len(ls):
                parts.append(ls[i])
            log = " ".join(x.strip() for x in parts).strip()
            rest, n = log, 0
            while True:
                m = _ASSIGN.match(rest)
                if not m:
                    break
                rest = rest[m.end():]; n += 1
            if n > 1 and not rest.strip():
                out.append(log)
        i += 1
    return out

_bad = 'TENANT_MANIFEST=build/manifest/pyron.toml TENANT_CHAR=0x11 \\\n    GF="--profile cps2-wide-v1"\n'
_ok1 = 'TENANT_MANIFEST=x TENANT_CHAR=0x11 \\\n    GEN_FLAGS="$GF" tools/build_donovan.sh 4 out\n'
_ok2 = 'CORPUS="01_attract_long \\\n    02_demitri_vs_cpu"\n'
for _name, _txt, _want in (("the real #84 shape", _bad, True),
                           ("the correct idiom (chain reaches a command)", _ok1, False),
                           ("a multi-line single value", _ok2, False)):
    _got = bool(_scan(_txt))
    _v = "ok" if _got == _want else "WRONG"
    print(f"  control: {_name}: {'flagged' if _got else 'silent'} [{_v}]")
    if _got != _want:
        sys.exit(1)
PY

echo "PASS: shell portability (no #!/bin/sh script uses a bash-only
      construct; no assignment-only continuation chain strands its vars)"
