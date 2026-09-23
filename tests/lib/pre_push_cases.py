#!/usr/bin/env python3
"""pre_push_cases.py HOOK — drives a C1 push hook (`tools/agent/hooks/pre_push.py`, GitHub
#172 slice S3) through every case against a scratch git repo with its own ledger; nothing
in the tree is touched. Exit 0 = every case as expected; each case prints expect/got.
Run by `tests/test_agent_hooks.sh` against the INSTALLED hook and, for its `open-push-hook`
control, against a perturbed copy. Born as build/agent172/proposal_pre_push/prove.py
(14z-176), where its four other-repository cases found the proposal's defect before install.

The hook imports `agentlib` from its parent directory, so the scratch layout is
<scratch>/tools/agent/{agentlib.py -> symlink to the tree's, hooks/pre_push.py}.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
TREE = os.path.dirname(os.path.dirname(HERE))
HOOK = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(TREE, "tools", "agent", "hooks", "pre_push.py")


def sh(cwd, *a):
    subprocess.run(a, cwd=cwd, check=True, capture_output=True, text=True)


def main():
    w = tempfile.mkdtemp()
    try:
        remote, repo = os.path.join(w, "remote.git"), os.path.join(w, "repo")
        sh(w, "git", "init", "-q", "--bare", remote)
        sh(w, "git", "init", "-q", "-b", "main", repo)
        for k, v in (("user.email", "t@t"), ("user.name", "t")):
            sh(repo, "git", "config", k, v)
        os.makedirs(os.path.join(repo, "tools", "agent", "hooks"))
        os.symlink(os.path.join(TREE, "tools", "agent", "agentlib.py"), os.path.join(repo, "tools", "agent", "agentlib.py"))
        shutil.copy(HOOK, os.path.join(repo, "tools", "agent", "hooks", "pre_push.py"))
        os.makedirs(os.path.join(repo, "tests", "rulecheck", "runs"))
        ledger = os.path.join(repo, "tests", "rulecheck", "ledger.tsv")
        open(ledger, "w").write("id\tdate\tsession\tdecision\tsubject\tcontrol\tcontrol_verdict\tverdict\tviolated\tresolution\tmodel\n")
        open(os.path.join(repo, "f"), "w").write("0")
        sh(repo, "git", "add", "-A"); sh(repo, "git", "commit", "-qm", "base")
        sh(repo, "git", "remote", "add", "origin", remote); sh(repo, "git", "push", "-q", "-u", "origin", "main")

        def commit(msg):
            open(os.path.join(repo, "f"), "a").write(msg)
            sh(repo, "git", "commit", "-qam", msg)
            return subprocess.run(["git", "-C", repo, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()

        def run_row(rid, verdict, head, resolution="-", caught="CAUGHT"):
            d = os.path.join(repo, "tests", "rulecheck", "runs", rid)
            os.makedirs(d, exist_ok=True)
            open(os.path.join(d, "meta.tsv"), "w").write(f"decision\tprocedure\nhead\t{head}\n")
            open(ledger, "a").write(f"{rid}\t2026-09-23\t14z-176\tprocedure\ts\tproc-x\t{caught}\t{verdict}\t{'QP1' if verdict == 'VIOLATED' else '-'}\t{resolution}\tm\n")

        def hook(cmd, raw=None):
            ev = raw if raw is not None else json.dumps({"hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": {"command": cmd}})
            p = subprocess.run([sys.executable, os.path.join(repo, "tools", "agent", "hooks", "pre_push.py")],
                               input=ev, capture_output=True, text=True, env=dict(os.environ, CLAUDE_PROJECT_DIR=repo))
            if p.returncode != 0:
                return f"exit{p.returncode}"
            return json.loads(p.stdout)["hookSpecificOutput"]["permissionDecision"] if p.stdout.strip() else "allow"

        cases = []
        cases.append(("nothing to push", hook("git push origin main"), "allow"))
        c1 = commit("work")
        cases.append(("a commit, no procedure run", hook("git push origin main"), "deny"))
        cases.append(("not a push", hook("git status && git log -1"), "allow"))
        cases.append(("push only quoted", hook("echo 'then git push origin main'"), "allow"))
        cases.append(("push in a heredoc body", hook("cat > n.txt <<'EOF'\ngit push origin main\nEOF"), "allow"))
        cases.append(("git -C dir push", hook(f"git -C {repo} push"), "deny"))
        run_row("r1", "VIOLATED", c1)
        cases.append(("VIOLATED, unresolved", hook("git push origin main"), "deny"))
        run_row("r2", "OK", c1, caught="DEAD")
        cases.append(("OK but a DEAD plant (VOID)", hook("git push origin main"), "deny"))
        run_row("r3", "VIOLATED", c1, resolution="QP1: carried out at [12]")
        cases.append(("VIOLATED and resolved, head in range", hook("git push origin main"), "allow"))
        c2 = commit("close")
        cases.append(("a later commit, the checked one still in range", hook("git push origin main"), "allow"))
        sh(repo, "git", "push", "-q", "origin", "main")
        commit("after the push")
        cases.append(("new commits, the check's head already pushed", hook("git push origin main"), "deny"))
        run_row("r4", "OK", c2)
        cases.append(("an OK run whose head is outside the range", hook("git push"), "deny"))
        cases.append(("malformed event fails open", hook("", raw="not json"), "allow"))
        # ANOTHER repository pushed from the same shell (the bbh harness, the jtcores fork)
        # while THIS repo has an unchecked commit: the hook must not judge it by this range
        commit("unchecked work in this repo")
        other, oremote = os.path.join(w, "other"), os.path.join(w, "other.git")
        sh(w, "git", "init", "-q", "--bare", oremote); sh(w, "git", "init", "-q", "-b", "main", other)
        for k, v in (("user.email", "t@t"), ("user.name", "t")):
            sh(other, "git", "config", k, v)
        open(os.path.join(other, "g"), "w").write("1"); sh(other, "git", "add", "-A"); sh(other, "git", "commit", "-qm", "o")
        sh(other, "git", "remote", "add", "origin", oremote); sh(other, "git", "push", "-q", "-u", "origin", "main")
        open(os.path.join(other, "g"), "a").write("2"); sh(other, "git", "commit", "-qam", "o2")
        cases.append(("this repo still denied with an unchecked commit", hook("git push origin main"), "deny"))
        cases.append(("git -C <other repo> push", hook(f"git -C {other} push origin main"), "allow"))
        cases.append(("cd <other repo> && git push", hook(f"cd {other} && git push origin main"), "allow"))
        ev_other = json.dumps({"hook_event_name": "PreToolUse", "tool_name": "Bash", "cwd": other,
                               "tool_input": {"command": "git push origin main"}})
        cases.append(("git push with the shell's cwd in the other repo", hook("", raw=ev_other), "allow"))
        bad = 0
        for name, got, want in cases:
            ok = got == want
            bad += 0 if ok else 1
            print(f"  {'ok  ' if ok else 'BAD '} {name}: expect {want}, got {got}")
        log = os.path.join(repo, "build", "agent_hooks", "errors.log")
        logged = os.path.exists(log) and "pre_push JSONDecodeError" in open(log).read()
        print(f"  {'ok  ' if logged else 'BAD '} the fail-open error was logged")
        bad += 0 if logged else 1
        print(f"prove: {len(cases) + 1} cases, {bad} wrong -> {'PASS' if not bad else 'FAIL'}")
        return 1 if bad else 0
    finally:
        shutil.rmtree(w, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
