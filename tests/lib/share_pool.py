#!/usr/bin/env python3
"""share_pool.py — WHAT A GATE SHARES, AND THE ONE TOKEN-AWARE SCHEDULER (#370, 14z-225; maintainer-ruled 2026-11-08
A1, B1, C1). Imported by tests/lib/static_pool.py (the static tier's pool); read by tests/run_all_emulator.sh
(`share_pool.py get`, whether a gate's controls may run beside one another); the census is tests/test_shares.sh.

THE FIELD — one line in a gate's leading comment block (every `#` line after the shebang up to the first other line):
    # SHARES: <token> [<token> …]        `self` = this gate's own jobs (its plain run, each control mode) never overlap;
                                         any other token is a resource of tests/shares.tsv
    # SHARES: none — <why nothing is shared>
A missing or malformed line reads as ['self'] here (the conservative value: nothing runs beside its siblings that did
not before), and the census fails it.

THE RULE every pool keeps: a job carries its gate's registry tokens, and `self:<gate>` when the gate declares `self`;
a job starts only when no running job holds any of its tokens; otherwise the first queued job that can start does
(no job waits holding a slot). A gate's control modes are queued only when its own run has ended, so a gate's plain run
never overlaps its own controls whatever it declares.

CLI:
    share_pool.py get <script>                 the tokens, one a line (`none` for none); exit 1 when missing/malformed
    share_pool.py census [--root R]            every registered gate (tests/ci_static.txt, ci_portable.txt, ci_emulator.tsv)
                                               carries one well-formed line; every token is `self` or a row of
                                               tests/shares.tsv; every row is held by a gate; a gate holding a row makes
                                               the row's claim call on a code line (with the token, for vs_shares_claim).
                                               One `<TAG>\t<gate or token>\t<detail>` line a problem (NO-LINE, MALFORMED,
                                               UNKNOWN-TOKEN, UNHELD, UNCLAIMED), then `census: …`; exit 1 on any problem
"""
import collections, os, re, subprocess, sys, time

LINE = re.compile(r"^# SHARES: (?:(none) — (.+)|([a-z0-9-]+(?: [a-z0-9-]+)*))$")


def header(path):
    out = []
    with open(path, encoding="utf-8", errors="replace") as f:
        for i, l in enumerate(f):
            if i == 0:
                continue
            if not l.startswith("#"):
                break
            out.append(l.rstrip("\n"))
    return out


def read(path):
    """(tokens, problem): tokens a list ([] for `none`), problem None or a short reason."""
    try:
        lines = [l for l in header(path) if l.startswith("# SHARES:")]
    except OSError as e:
        return None, "unreadable: %s" % e
    if not lines:
        return None, "no `# SHARES:` line in the leading comment block"
    if len(lines) > 1:
        return None, "%d `# SHARES:` lines (exactly one)" % len(lines)
    m = LINE.match(lines[0])
    if not m:
        return None, "malformed: %r" % lines[0]
    if m.group(1):
        return [], None
    toks = m.group(3).split()
    if len(set(toks)) != len(toks):
        return None, "a token named twice: %r" % lines[0]
    if "none" in toks:
        return None, "`none` must stand alone with its reason: %r" % lines[0]
    return toks, None


def tokens(path, gate):
    """The scheduling tokens of a job of this gate: its registry tokens, and self:<gate> when it declares self."""
    toks, problem = read(path)
    if toks is None:
        toks = ["self"]
    return frozenset(("self:" + gate) if t == "self" else t for t in toks)   # SHARE-SELF


def registry(root="."):
    out = {}
    with open(os.path.join(root, "tests", "shares.tsv"), encoding="utf-8") as f:
        for l in f:
            if l.startswith("#") or not l.strip():
                continue
            c = l.rstrip("\n").split("\t")
            out[c[0]] = c
    return out


def registered(root):
    out = []
    for name in ("ci_static.txt", "ci_portable.txt", "ci_emulator.tsv"):
        with open(os.path.join(root, "tests", name), encoding="utf-8") as f:
            for l in f:
                if l.startswith("#") or not l.strip():
                    continue
                g = os.path.basename(l.split("\t")[0].split()[0])
                g = g[:-3] if g.endswith(".sh") else g
                if g not in out:
                    out.append(g)
    return out


def census(root):
    reg = registry(root)
    probs, held, n = [], set(), 0
    for g in registered(root):
        p = os.path.join(root, "tests", g + ".sh")
        n += 1
        toks, problem = read(p)
        if toks is None:
            probs.append(("NO-LINE" if problem.startswith("no ") else "MALFORMED", g, problem))
            continue
        code = None
        for t in toks:
            if t == "self":
                continue
            if t not in reg:
                probs.append(("UNKNOWN-TOKEN", g, "%s is neither self nor a row of tests/shares.tsv" % t))
                continue
            held.add(t)
            if code is None:
                with open(p, encoding="utf-8", errors="replace") as f:
                    code = [l for l in f if not l.lstrip().startswith("#")]
            call = reg[t][2] if len(reg[t]) > 2 else "vs_shares_claim"
            pat = re.compile(r"\b%s\b" % re.escape(call) + (r".*\b%s\b" % re.escape(t) if call == "vs_shares_claim" else ""))
            if not any(pat.search(l) for l in code):
                probs.append(("UNCLAIMED", g, "holds %s but makes no %s call for it on a code line" % (t, call)))
    for t in reg:
        if t not in held:
            probs.append(("UNHELD", t, "a row of tests/shares.tsv no registered gate holds"))
    return n, len(reg), probs


class Pool:
    """N slots; a deque of tasks (key, tokens, argv); start(task) -> Popen; done(task, rc, start, end) is called."""

    def __init__(self, jobs, start, done):
        self.jobs, self.start, self.done = jobs, start, done
        self.queue = collections.deque()
        self.running = {}   # slot -> (Popen, task, t0)
        self.free = list(range(jobs))

    def held(self):
        h = set()
        for _p, task, _t in self.running.values():
            h |= task[1]
        return h

    def pick(self):   # SHARE-PICK: the first queued task none of whose tokens a running job holds
        h = self.held()
        for i, task in enumerate(self.queue):
            if not (task[1] & h):   # SHARE-PICK
                del self.queue[i]
                return task
        return None

    def run(self):
        while self.queue or self.running:
            while self.free and self.queue:
                task = self.pick()
                if task is None:
                    break
                slot = self.free.pop(0)
                self.running[slot] = (self.start(task, slot), task, time.time())
            time.sleep(0.05)
            for slot, (p, task, t0) in list(self.running.items()):
                rc = p.poll()
                if rc is None:
                    continue
                del self.running[slot]
                self.free.append(slot); self.free.sort()
                self.done(task, rc, slot, t0, time.time())


def main(argv):
    if len(argv) == 3 and argv[1] == "get":
        toks, problem = read(argv[2])
        if toks is None:
            print("share_pool.py: %s: %s" % (argv[2], problem), file=sys.stderr)
            return 1
        print("\n".join(toks) if toks else "none")
        return 0
    if len(argv) >= 2 and argv[1] == "census":
        root = argv[argv.index("--root") + 1] if "--root" in argv else "."
        n, nreg, probs = census(root)
        for p in probs:
            print("%s\t%s\t%s" % p)
        print("census: %d registered gates read, %d registry tokens, %d problem(s)" % (n, nreg, len(probs)))
        return 1 if probs else 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
