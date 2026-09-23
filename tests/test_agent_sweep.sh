#!/bin/sh
# test_agent_sweep.sh — SLICE S2 OF GitHub #172: C0.3, the close-time process sweep
# (`tools/agent/sweep.py`), names every survivor it must and nothing it must not
# (docs/project/agent_architecture_scope.md §4 C0.3, 2026-09-23).
#
# A synthetic process world, planted live, because the sweep reads the real process
# table and nothing else would test it:
#   - a FAKE CLAUDE process with (a) a tool shell — a session-leader child running a
#     long job, which must be named ATTACHED with its child — and (b) a helper that is a
#     child but NOT a session leader (Claude Code's own `caffeinate`, measured), which
#     must stay quiet; the sweep itself runs from a third leader child of the fake Claude
#     and must not name its own shell;
#   - SIX ORPHANS reparented to launchd/init, one per signal: cwd in the root (a Python
#     job, and a `sh`+`tail` pair — the platform-binary shape whose environment macOS
#     hides, measured 14z-176 on the 18-day `tail | ugrep` it found), the root on the
#     command line, a standard stream into the root, the swept session id in the
#     environment, and an orphaned Claude tool shell (`.claude/shell-snapshots/`);
#   - ONE QUIET ORPHAN pointing nowhere near the root, which must not be named.
# Then every survivor is DECLARED and the sweep must say CLEAN with each one declared;
# then every plant is killed and it must say CLEAN with no survivor, the quiet orphan and
# the helper still alive. Every plant runs with the CLAUDE_* environment scrubbed, so a
# real session's sweep cannot mistake the gate's world for its own, and every pid is
# killed on exit.
#
# MUST-FIRE: perturbed-copy: blind-orphans — a copy of the sweep whose orphan scan returns no candidate must miss all six orphans, and the gate must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: blind-cwd — a copy that never matches a working directory must miss the two cwd-only orphans, the `tail` shape among them, and the gate must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: blind-leaders — a copy that treats no child of Claude as a tool shell must miss the ATTACHED plant, and the gate must FAIL (mode: the gate runs against that copy)
#
# Usage: tests/test_agent_sweep.sh      # ci_portable, ~10 s (macOS: ps + lsof; Linux: /proc)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"
cleanup() {
    if [ -f "$W/pids" ]; then
        # leaves first is not knowable here; TERM everything the harness ever planted
        for p in $(sort -rn "$W/pids"); do kill "$p" 2>/dev/null || true; done
    fi
    rm -rf "$W"
}
trap cleanup EXIT

# make_copy <name> — a copy of tools/agent with ONE perturbation, for the controls
make_copy() {
    mkdir -p "$W/$1"; cp -R tools/agent "$W/$1/agent"
    python3 - "$W/$1/agent/sweep.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
edits = {
    "blind-orphans": ('def orphan_roots(procs, uid, exclude):\n',
                      'def orphan_roots(procs, uid, exclude):\n    return []  # CONTROL blind-orphans\n'),
    "blind-cwd": ('        if under(fi.get("cwd"), roots):\n',
                  '        if False:  # CONTROL blind-cwd\n'),
    "blind-leaders": ('        if getsid(c) != c:\n',
                      '        if True:  # CONTROL blind-leaders\n'),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/agent/sweep.py"
}

# world <sweep.py> <outdir> — plant the world, run the sweep through its three phases,
# and write <outdir>/verdict.txt (one line per mismatch, then a SUMMARY line)
world() {
    mkdir -p "$2"
    python3 - "$1" "$2" "$W/pids" <<'PY'
import json, os, subprocess, sys, time
sweep, out, pidfile = sys.argv[1:4]
root = os.path.realpath(os.path.join(out, "root")); os.makedirs(root, exist_ok=True)
SESSION = "gate-fake-session-0000-0000-000000000000"
env = {k: v for k, v in os.environ.items() if not k.startswith("CLAUDE")}
PY_SLEEP = [sys.executable, "-c", "import time; time.sleep(300)"]

def note(pid):
    with open(pidfile, "a") as f:
        f.write(f"{pid}\n")

def orphan(tag, argv, cwd, extra_env=None, stdout=None):
    """Spawn argv in a new session through a parent that exits at once, so the child is
    reparented to launchd/init — the shape a detached job takes when its shell exits."""
    e = dict(env, **(extra_env or {}))
    spec = json.dumps({"argv": argv, "cwd": cwd, "env": e, "stdout": stdout})
    code = ("import json, subprocess, sys; s = json.loads(sys.argv[1]); "
            "o = open(s['stdout'], 'w') if s['stdout'] else subprocess.DEVNULL; "
            "p = subprocess.Popen(s['argv'], cwd=s['cwd'], env=s['env'], stdin=subprocess.DEVNULL, "
            "stdout=o, stderr=subprocess.DEVNULL, start_new_session=True); print(p.pid)")
    pid = int(subprocess.run([sys.executable, "-c", code, spec], capture_output=True, text=True, check=True).stdout)
    note(pid)
    return pid

open(os.path.join(root, "log.txt"), "w").close()
plants = {
    "o1-cwd": orphan("o1", PY_SLEEP + ["sweep-plant-o1"], root),
    "o2-cwd-tail": orphan("o2", ["sh", "-c", "tail -f /dev/null; true"], root),
    "o3-argv": orphan("o3", ["tail", "-f", os.path.join(root, "log.txt")], "/"),
    "o4-stream": orphan("o4", PY_SLEEP + ["sweep-plant-o4"], "/", stdout=os.path.join(root, "out.txt")),
    "o5-env": orphan("o5", PY_SLEEP + ["sweep-plant-o5"], "/", {"CLAUDE_CODE_SESSION_ID": SESSION}),
    "o6-claude-shell": orphan("o6", ["sh", "-c", f"{sys.executable} -c 'import time; time.sleep(300)'; true",
                                     "/x/.claude/shell-snapshots/snapshot-gate.sh"], "/"),
    "q1-quiet": orphan("q1", PY_SLEEP + ["sweep-plant-q1"], "/"),
}
want_sig = {"o1-cwd": "cwd", "o2-cwd-tail": "cwd", "o3-argv": "argv", "o4-stream": "stream",
            "o5-env": "env", "o6-claude-shell": "claude-shell"}

# the fake Claude: spawns its tool shell and helper, runs the sweep from a leader child
# through the three phases, kills every plant, and reports as JSON
FAKE = r'''
import json, os, subprocess, sys, time
sweep, root, decl, session, plants, env = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], json.loads(sys.argv[5]), json.loads(sys.argv[6])
me = os.getpid()
tool = subprocess.Popen(["sh", "-c", sys.executable + " -c 'import time; time.sleep(300)' sweep-plant-attached; true"],
                        cwd="/", env=env, start_new_session=True)
helper = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(300)", "sweep-plant-helper"], cwd="/", env=env)
# poll (bounded) until the tool shell has forked its job: an empty child list would make
# the "child listed under it" check pass vacuously
for _ in range(100):
    tool_child = [int(l.split()[0]) for l in subprocess.run(["ps", "-Ao", "pid=,ppid="], capture_output=True, text=True).stdout.splitlines() if int(l.split()[1]) == tool.pid]
    if tool_child:
        break
    time.sleep(0.1)
def run(*extra):
    p = subprocess.run([sys.executable, sweep, "--claude-pid", str(me), "--session", session, "--root", root,
                        "--declared", decl, "--transcript", "/nonexistent/transcript.jsonl", *extra],
                       capture_output=True, text=True, env=env, start_new_session=True)
    return {"rc": p.returncode, "out": p.stdout + p.stderr}
res = {"fake": me, "tool": tool.pid, "tool_child": tool_child, "helper": helper.pid}
res["r1"] = run()
named = [int(l.split()[1]) for l in res["r1"]["out"].splitlines() if l.split()[:1] and l.split()[0] in ("ATTACHED", "ORPHAN")]
res["declares"] = [run("--declare", str(p), "gate plant, killed at the end of the gate")["rc"] for p in named]
res["r2"] = run()
# kill every plant LEAVES FIRST, by its exact subtree: killing only a parent would orphan
# its child (o2's tail, o6's python) and phase 3 would rightly name it
kids = {}
for l in subprocess.run(["ps", "-Ao", "pid=,ppid="], capture_output=True, text=True).stdout.splitlines():
    c, pp = map(int, l.split()); kids.setdefault(pp, []).append(c)
def sub(r):
    o = [r]; i = 0
    while i < len(o):
        o += kids.get(o[i], []); i += 1
    return o
for r in [tool.pid] + [p for k, p in plants.items() if not k.startswith("q")]:
    for q in reversed(sub(r)):
        try:
            os.kill(q, 15)
        except OSError:
            pass
time.sleep(0.4)
res["r3"] = run()
res["alive_after"] = {"helper": helper.poll() is None}
helper.kill()
print(json.dumps(res))
'''
# poll (bounded) until every orphan is reparented and the two `sh` plants have forked
# their child — a fixed sleep would let a loaded machine test a half-built world
for _ in range(100):
    ppid = {int(l.split()[0]): int(l.split()[1]) for l in subprocess.run(["ps", "-Ao", "pid=,ppid="], capture_output=True, text=True).stdout.splitlines()}
    parents = set(ppid.values())
    if all(ppid.get(p) is not None and ppid.get(p) != os.getpid() for p in plants.values()) and \
       plants["o2-cwd-tail"] in parents and plants["o6-claude-shell"] in parents:
        break
    time.sleep(0.1)
# the plants' own children go into the cleanup list too, so a crash cannot leak them
for pid in plants.values():
    for c, pp in ppid.items():
        if pp == pid:
            note(c)
p = subprocess.run([sys.executable, "-c", FAKE, sweep, root, os.path.join(out, "declared.tsv"), SESSION,
                    json.dumps(plants), json.dumps(env)], capture_output=True, text=True, env=env)
note_bad = []
try:
    res = json.loads(p.stdout.strip().splitlines()[-1])
except Exception:
    print(f"MISMATCH the fake Claude died: {p.stderr[-400:]}")
    print("SUMMARY mismatches 1"); sys.exit(0)
for k in ("r1", "r2", "r3"):
    open(os.path.join(out, f"{k}.txt"), "w").write(res[k]["out"])
bad = []
# the world itself must be what the gate says it is
for k, pid in plants.items():
    if ppid.get(pid) is None:
        bad.append(f"plant {k} ({pid}) was not alive before the sweep")
for k in ("o2-cwd-tail", "o6-claude-shell"):
    if plants[k] not in set(ppid.values()):
        bad.append(f"plant {k} had not forked its child before the sweep")
if not res["tool_child"]:
    bad.append("the fake Claude's tool shell had not forked its job before the sweep")
r1 = res["r1"]["out"].splitlines()
rows = {int(l.split()[1]): l for l in r1 if l.split()[:1] and l.split()[0] in ("ATTACHED", "ORPHAN")}
if res["r1"]["rc"] != 1:
    bad.append(f"phase 1: exit {res['r1']['rc']}, want 1 (survivors)")
if res["tool"] not in rows or not rows[res["tool"]].startswith("ATTACHED"):
    bad.append(f"phase 1: the tool shell {res['tool']} was not named ATTACHED")
elif not all(any(l.strip().startswith(f"└ {c} ") for l in r1) for c in res["tool_child"]):
    bad.append("phase 1: the tool shell's child was not listed under it")
for k, sig in want_sig.items():
    pid = plants[k]
    if pid not in rows or not rows[pid].startswith("ORPHAN"):
        bad.append(f"phase 1: orphan {k} ({pid}) was not named")
    elif sig not in rows[pid].split("signals ", 1)[1].split(",")[0].split("+"):
        bad.append(f"phase 1: orphan {k} named without its signal {sig}: {rows[pid]}")
if not any(l.strip().startswith("└ ") and "tail -f /dev/null" in l for l in r1):
    bad.append("phase 1: o2's `tail` child was not listed under its `sh`")
for k, pid in (("q1-quiet", plants["q1-quiet"]), ("helper", res["helper"]), ("fake claude", res["fake"])):
    if pid in rows:
        bad.append(f"phase 1: {k} ({pid}) was named and must stay quiet")
extra = set(rows) - {res["tool"]} - {plants[k] for k in want_sig}
if extra:
    bad.append(f"phase 1: unexpected survivors named (the sweep's own shell?): {sorted(extra)}")
if any(rc != 0 for rc in res["declares"]):
    bad.append(f"declare: exits {res['declares']}")
r2 = res["r2"]["out"]
if res["r2"]["rc"] != 0 or "CLEAN:" not in r2 or r2.count("\nDECLARED ") + r2.startswith("DECLARED ") != len(rows):
    bad.append(f"phase 2: every survivor declared must read CLEAN with {len(rows)} DECLARED rows (exit {res['r2']['rc']})")
if res["r3"]["rc"] != 0 or "CLEAN: no survivor" not in res["r3"]["out"]:
    bad.append(f"phase 3: after the kill the sweep must read CLEAN: no survivor (exit {res['r3']['rc']})")
if not res["alive_after"]["helper"]:
    bad.append("phase 3: the helper died — the quiet case was not tested alive")
for b in bad:
    print(f"MISMATCH {b}")
print(f"SUMMARY named {len(rows)} (want {1 + len(want_sig)}) mismatches {len(bad)}")
PY
}

echo "== test_agent_sweep: #172 slice S2 — C0.3 against a planted process world =="
fail=0
SW=tools/agent/sweep.py
if vs_ctl_is blind-orphans || vs_ctl_is blind-cwd || vs_ctl_is blind-leaders; then SW="$(make_copy "$VS_CTL")"; fi
world "$SW" "$W/main" > "$W/main.txt"
sed -n '/^MISMATCH/p' "$W/main.txt" | head -12 | sed 's/^/  /'
tail -1 "$W/main.txt" | sed 's/^/  /'
grep -q ' mismatches 0$' "$W/main.txt" || { echo "FAIL: the sweep's report disagrees with the planted world"; sed 's/^/    | /' "$W/main/r1.txt" 2>/dev/null | head -30; fail=1; }

# the controls, in-gate: each perturbed copy must produce mismatches
if [ -z "${VS_CTL:-}" ]; then
    for c in blind-orphans blind-cwd blind-leaders; do
        world "$(make_copy "$c")" "$W/ctl_$c" > "$W/ctl_$c.txt"
        k=$(grep -c '^MISMATCH' "$W/ctl_$c.txt" || true)
        if [ "${k:-0}" -gt 0 ]; then vs_ctl_fired "$c" "$k mismatches on the perturbed copy, e.g. $(grep -m1 '^MISMATCH' "$W/ctl_$c.txt" | cut -c10-110)"
        else vs_ctl_dead "$c" "the perturbed copy matched the planted world — the gate cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: C0.3 names the ATTACHED tool shell and all six orphan shapes by their signals, stays quiet on the helper, the quiet orphan and itself, reads CLEAN once each is declared, and CLEAN with no survivor once they are killed"
else echo "FAIL: test_agent_sweep"; exit 1; fi
