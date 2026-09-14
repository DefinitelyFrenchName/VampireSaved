#!/usr/bin/env python3
"""tickets.py — THE TICKET INDEX: every bug, cosmetic item and evolution, one row each.

  python3 tools/tickets.py check              # validate docs/project/tickets.tsv (offline)
  python3 tools/tickets.py page               # rewrite docs/project/tickets.md
  python3 tools/tickets.py page --check       # regenerate in memory, diff against disk
  python3 tools/tickets.py refresh            # save GitHub's issue list (network, `gh`)
  python3 tools/tickets.py seed               # print a `?` row for every saved issue
                                              #   that has no row (a backfill's start)
  --root DIR                                  # a copy of the tree
  --index/--snapshot/--debt/--page PATH       # one file from elsewhere (the gate's
                                              #   must-fire controls; links still
                                              #   resolve under --root)

WHY THIS EXISTS (14z-154; maintainer-ruled 2026-09-14, CLAUDE.md [VSP-182]).
Open items were listed in STATE.md's standing sections and marked closed IN
PLACE, so the open lists filled with closed items while GitHub, the docs and
STATE each carried their own copy of an item's status. The ruling gives each
question about a ticket ONE source of truth: the LIST is
`docs/project/tickets.tsv` (its header is the spec of record), the STORY is the
GitHub issue, the FACTS are the subject documents, and what a session did is
STATE. This tool makes the list checkable: every saved GitHub issue has exactly
one row, a row's open/closed agrees with GitHub's, and every row answers the
four local questions — how to reproduce it, what was decided, what was learned,
what went wrong — with links that RESOLVE or an explicit `none`.

WHAT IT DOES NOT CLAIM: that an answer is ENOUGH. The form is checked; whether
the linked documents let someone without GitHub understand and work from the
ticket is judged at the close that closes it ([VSP-182]). Nor that the saved
GitHub list is current: `refresh` is a close-ritual step, and the gate compares
against what was saved.
ROM-free, emulator-free, well under a second (ci_portable, tests/test_tickets.sh).
"""
import argparse
import difflib
import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
INDEX = "docs/project/tickets.tsv"
SNAPSHOT = "docs/project/tickets_github.tsv"
DEBT = "tests/expected/tickets_debt.txt"
PAGE = "docs/project/tickets.md"

COLS = ["issue", "kind", "status", "title", "repro", "decided", "learned", "wrong", "sessions"]
SNAP_COLS = ["number", "state", "reason", "closed", "labels", "title"]
KINDS = ["bug", "cosmetic", "evolution"]
OPEN_STATUSES = ["open", "parked"]
CLOSED_STATUSES = ["done", "declined", "not-ours", "invalid", "duplicate"]
ANSWERS = ["repro", "decided", "learned", "wrong"]
LIVE_ONLY = ["learned", "wrong"]      # rule (1) of the 2026-09-14 ruling
DEBT_MARK = "?"
LINK_SEP = " ; "
ANCHOR_SEP = " § "
KEY_RE = re.compile(r"^[0-9][0-9a-z]*(?:-[0-9a-z]+)*$")
REPO_RE = re.compile(r"^#\s*repo:\s*(\S+)")


def not_live(path):
    """STATE.md rolls and the *_HISTORY.md / *_history.md files are archives."""
    name = Path(path).name
    return name == "STATE.md" or name.endswith("_HISTORY.md") or name.endswith("_history.md")


def read_table(path, cols):
    """Rows of a tab-separated file: `#` comments, one column line, then data."""
    rows, fails, repo, header = [], [], None, False
    p = Path(path)
    if not p.is_file():
        return rows, [f"{path}: missing"], repo
    for n, line in enumerate(p.read_text().splitlines(), 1):
        m = REPO_RE.match(line)
        if m:
            repo = m.group(1)
        if not line.strip() or line.startswith("#"):
            continue
        cells = line.split("\t")
        if not header:
            header = True
            if cells != cols:
                fails.append(f"{path}:{n}: the column line must be exactly: " + " ".join(cols))
            continue
        if len(cells) != len(cols):
            fails.append(f"{path}:{n}: {len(cells)} fields where {len(cols)} are expected")
            continue
        rows.append((n, dict(zip(cols, [c.strip() for c in cells]))))
    if not header:
        fails.append(f"{path}: no column line")
    return rows, fails, repo


def read_debt(path):
    p = Path(path)
    if not p.is_file():
        return set(), [f"{path}: missing"]
    out, fails = set(), []
    for n, line in enumerate(p.read_text().splitlines(), 1):
        s = line.split("#", 1)[0].strip()
        if not s:
            continue
        if not s.isdigit():
            fails.append(f"{path}:{n}: `{s}` is not an issue number")
            continue
        out.add(int(s))
    return out, fails


class Tree:
    """Link and session-key resolution under one root, with file reads cached."""

    def __init__(self, root):
        self.root = root
        self._text = {}

    def text(self, rel):
        if rel not in self._text:
            self._text[rel] = (self.root / rel).read_text(errors="replace")
        return self._text[rel]

    def link_error(self, link):
        path, _, anchor = link.partition(ANCHOR_SEP)
        path = path.strip()
        if not path or path.startswith("/") or ".." in Path(path).parts:
            return "is not a repo-relative path"
        f = self.root / path
        if not f.exists():
            return f"names `{path}`, which does not exist"
        if anchor:
            if f.is_dir():
                return f"anchors text in `{path}`, which is a directory"
            if anchor.strip() not in self.text(path):
                return f"anchors “{anchor.strip()}”, which no line of `{path}` contains"
        return None

    def session_resolves(self, key):
        # A record is a `Session <key>` line, a `**<key>` lead, or a `##`/`###`
        # heading that BEGINS with the key: a session archived as a sub-entry of
        # another's group has only that last form (THE LEDGER says so of 14z-90,
        # whose record is `### 14z-90 —` inside the 14z-91 group). Measured when
        # the heading form was added (2026-09-14): 34 keys resolve only by it,
        # every one a real record; an invented key still resolves nowhere.
        pat = re.compile(r"(?:Sessions?\s+|\*\*|^#{2,3} )" + re.escape(key) + r"(?![0-9A-Za-z])", re.M)
        for rel in ("STATE.md", "STATE_HISTORY.md"):
            if (self.root / rel).is_file() and pat.search(self.text(rel)):
                return True
        return False


def check(tree, index, snapshot, debt):
    fails = []
    rows, f, repo = read_table(index, COLS)
    fails += f
    snap_rows, f, snap_repo = read_table(snapshot, SNAP_COLS)
    fails += f
    debt_set, f = read_debt(debt)
    fails += f
    if repo is None:
        fails.append(f"{INDEX}: no `# repo: owner/name` line")
    if snap_repo is None:
        fails.append(f"{SNAPSHOT}: no `# repo: owner/name` line")
    if repo and snap_repo and repo != snap_repo:
        fails.append(f"{INDEX} names repo {repo} but {SNAPSHOT} was saved from {snap_repo}")
    snap = {}
    for n, r in snap_rows:
        if r["number"].isdigit():
            snap[int(r["number"])] = r
        else:
            fails.append(f"{SNAPSHOT}:{n}: `{r['number']}` is not an issue number")

    seen, order = {}, []
    for n, r in rows:
        where = f"{INDEX}:{n}"
        if not r["issue"].isdigit():
            fails.append(f"{where}: issue `{r['issue']}` is not a number")
            continue
        i = int(r["issue"])
        where = f"{where} #{i}"
        if i in seen:
            fails.append(f"{where}: a second row for #{i} (the first is line {seen[i]})")
            continue
        seen[i] = n
        order.append(i)
        marks = [c for c in COLS[1:] if r[c] == DEBT_MARK]
        if marks and i not in debt_set:
            fails.append(f"{where}: `?` in {', '.join(marks)}, and #{i} is not in the backfill debt "
                         f"({DEBT}) — the debt only shrinks: answer the column")
        if not marks and i in debt_set:
            fails.append(f"{where}: fully backfilled — retire #{i} from {DEBT} in this commit")
        if r["kind"] not in KINDS + [DEBT_MARK]:
            fails.append(f"{where}: kind `{r['kind']}` is not one of {' / '.join(KINDS)}")
        st = r["status"]
        if st not in OPEN_STATUSES + CLOSED_STATUSES + [DEBT_MARK]:
            fails.append(f"{where}: status `{st}` is not one of {' / '.join(OPEN_STATUSES + CLOSED_STATUSES)}")
        if r["title"] in ("", DEBT_MARK):
            fails.append(f"{where}: the title must be one searchable line in our words")
        g = snap.get(i)
        if g is None:
            fails.append(f"{where}: #{i} is not in the saved GitHub list ({SNAPSHOT}) — create the "
                         f"issue first, then `tools/tickets.py refresh`")
        elif st in OPEN_STATUSES + CLOSED_STATUSES and (st in OPEN_STATUSES) != (g["state"] == "OPEN"):
            fails.append(f"{where}: status `{st}` but the issue is {g['state']} on GitHub — "
                         f"closed means nothing is left to do; reconcile one side")
        for c in ANSWERS:
            v = r[c]
            if v in ("none", DEBT_MARK):
                continue
            if not v:
                fails.append(f"{where}: {c} is empty — write `none` or links")
                continue
            for link in v.split(LINK_SEP):
                err = tree.link_error(link)
                if err:
                    fails.append(f"{where}: {c} link {err}")
                elif c in LIVE_ONLY and not_live(link.partition(ANCHOR_SEP)[0].strip()):
                    fails.append(f"{where}: {c} link `{link}` is not a live document — what was learned "
                                 f"and what went wrong live in a subject doc, a gotchas bucket or a "
                                 f"skill, never only in STATE.md or an archive")
        s = r["sessions"]
        if s not in ("-", DEBT_MARK):
            for key in [k.strip() for k in s.split(",")]:
                if not KEY_RE.match(key) or not tree.session_resolves(key):
                    fails.append(f"{where}: session key `{key}` resolves to no record in "
                                 f"STATE.md or STATE_HISTORY.md")
    for i in sorted(set(snap) - set(seen), reverse=True):
        fails.append(f"{SNAPSHOT}: #{i} ({snap[i]['state']}) has no row in {INDEX} — every issue has "
                     f"exactly one row")
    for i in sorted(debt_set - set(seen), reverse=True):
        fails.append(f"{DEBT}: #{i} has no row in {INDEX}")
    if order != sorted(order, reverse=True):
        fails.append(f"{INDEX}: rows must be ordered newest issue first")
    return rows, snap, repo, debt_set, fails


def cell(s):
    """A table cell for the markdown subset: an escaped pipe, no raw HTML."""
    return s.replace("|", "\\|").replace("<", "‹").replace(">", "›")


def answer_cell(v):
    if v in ("none", DEBT_MARK):
        return v
    return " · ".join(f"`{cell(link)}`" for link in v.split(LINK_SEP))


def render(rows, snap, repo, debt_set):
    data = [r for _, r in rows]
    by_status = {}
    for r in data:
        by_status[r["status"]] = by_status.get(r["status"], 0) + 1
    by_kind = {}
    for r in data:
        by_kind[r["kind"]] = by_kind.get(r["kind"], 0) + 1
    status_line = " · ".join(f"{k} {by_status[k]}" for k in OPEN_STATUSES + CLOSED_STATUSES + [DEBT_MARK]
                             if by_status.get(k))
    kind_line = " · ".join(f"{k} {by_kind[k]}" for k in KINDS + [DEBT_MARK] if by_kind.get(k))
    out = [
        "# The ticket index (GENERATED)",
        "",
        "<!-- generated by tools/tickets.py from docs/project/tickets.tsv — do not edit; regenerate -->",
        "",
        "**STATUS: GENERATED (14z-154).** Every bug, cosmetic item and evolution of this project, one",
        "row per GitHub issue, rendered from `docs/project/tickets.tsv` — the source of truth for the",
        "LIST (CLAUDE.md [VSP-182]); that file's header is the spec of record and names what each",
        "column means. A ticket's STORY is its GitHub issue; what it established lives in the",
        "documents its links name, and the four answer columns (repro, decided, learned, wrong) are",
        "what lets the tree be understood without GitHub. `?` marks a row not yet backfilled — the",
        "backfill debt, which only shrinks. Regenerate with `python3 tools/tickets.py page`;",
        "`tests/test_tickets.sh` fails on drift.",
        "",
        f"**{len(data)} tickets** — status: {status_line} · kind: {kind_line} · "
        f"**backfill debt: {len(debt_set)} rows**.",
    ]
    head = ["", "| # | kind | status | ticket | repro | decided | learned | wrong | sessions |",
            "|---|---|---|---|---|---|---|---|---|"]
    for title, pick in (("Open and parked", lambda r: r["status"] in OPEN_STATUSES),
                        ("Closed", lambda r: r["status"] in CLOSED_STATUSES),
                        ("Not yet classified", lambda r: r["status"] == DEBT_MARK)):
        chosen = [r for r in data if pick(r)]
        out += ["", f"## {title}"]
        if not chosen:
            out += ["", "*None.*"]
            continue
        out += head
        for r in chosen:
            link = f"[#{r['issue']}](https://github.com/{repo}/issues/{r['issue']})" if repo else f"#{r['issue']}"
            out.append("| " + " | ".join([link, r["kind"], r["status"], cell(r["title"])]
                                         + [answer_cell(r[c]) for c in ANSWERS]
                                         + [cell(r["sessions"])]) + " |")
    return "\n".join(out) + "\n"


def refresh(index, snapshot, limit=1000):
    # the repository is the one the INDEX declares, passed explicitly: a saved
    # list can never come from a different repo than the rows describe, and the
    # tool does not depend on the working directory being a checkout
    _, _, repo = read_table(index, COLS)
    if not repo:
        sys.exit(f"REFUSED: {index} names no `# repo: owner/name` line — refresh saves the list of the "
                 f"repository the index declares")

    def gh(*args):
        p = subprocess.run(["gh", *args], capture_output=True, text=True)
        if p.returncode:
            sys.exit(f"REFUSED: `gh {' '.join(args[:2])}` failed ({p.returncode}): {p.stderr.strip()}")
        return p.stdout
    issues = json.loads(gh("issue", "list", "--repo", repo, "--state", "all", "--limit", str(limit),
                           "--json", "number,state,stateReason,closedAt,labels,title"))
    if len(issues) >= limit:
        sys.exit(f"REFUSED: gh returned {len(issues)} issues, the limit — the list may be truncated")
    if not issues:
        sys.exit(f"REFUSED: gh returned no issues for {repo} — a broken instrument, not an empty tracker")
    clean = lambda s: " ".join(str(s).split())
    lines = [
        "# docs/project/tickets_github.tsv — GitHub's issue list as SAVED by `tools/tickets.py refresh`",
        "# (network; a session-close step). GENERATED — never hand-edited. tools/tickets.py check",
        "# compares each ticket row's open/closed against it OFFLINE (CLAUDE.md [VSP-182]).",
        f"# repo: {repo}",
        f"# issues: {len(issues)}",
        "\t".join(SNAP_COLS),
    ]
    for i in sorted(issues, key=lambda x: -x["number"]):
        labels = ",".join(sorted(l["name"] for l in i.get("labels", []))) or "-"
        lines.append("\t".join([str(i["number"]), i["state"], i.get("stateReason") or "-",
                                (i.get("closedAt") or "-")[:10], clean(labels), clean(i["title"])]))
    Path(snapshot).write_text("\n".join(lines) + "\n")
    print(f"saved {len(issues)} issues of {repo} to {snapshot}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("cmd", choices=["check", "page", "refresh", "seed"])
    ap.add_argument("--check", action="store_true", help="page: diff against the file instead of writing")
    ap.add_argument("--root", default=str(REPO))
    ap.add_argument("--index")
    ap.add_argument("--snapshot")
    ap.add_argument("--debt")
    ap.add_argument("--page")
    a = ap.parse_args()
    root = Path(a.root).resolve()
    index = Path(a.index) if a.index else root / INDEX
    snapshot = Path(a.snapshot) if a.snapshot else root / SNAPSHOT
    debt = Path(a.debt) if a.debt else root / DEBT
    page = Path(a.page) if a.page else root / PAGE

    if a.cmd == "refresh":
        refresh(index, snapshot)
        return 0
    if a.cmd == "seed":
        rows, _, _ = read_table(index, COLS)
        have = {int(r["issue"]) for _, r in rows if r["issue"].isdigit()}
        snap_rows, _, _ = read_table(snapshot, SNAP_COLS)
        for _, s in snap_rows:
            if s["number"].isdigit() and int(s["number"]) not in have:
                print("\t".join([s["number"], "?", "?", s["title"], "?", "?", "?", "?", "?"]))
        return 0

    rows, snap, repo, debt_set, fails = check(Tree(root), index, snapshot, debt)
    if a.cmd == "page":
        text = render(rows, snap, repo, debt_set)
        if a.check:
            old = page.read_text() if page.is_file() else ""
            if old != text:
                print(f"FAIL: {PAGE} differs from a regeneration — run `python3 tools/tickets.py page`")
                sys.stdout.writelines(list(difflib.unified_diff(
                    old.splitlines(True), text.splitlines(True), "on disk", "regenerated"))[:40])
                return 1
            print(f"PASS: {PAGE} is current ({len(rows)} tickets)")
            return 0
        page.write_text(text)
        print(f"wrote {page} ({len(rows)} tickets)")
        return 0

    for f in fails:
        print(f"  FAIL  {f}")
    debt_rows = sum(1 for _, r in rows if any(r[c] == DEBT_MARK for c in COLS[1:]))
    if fails:
        print(f"FAIL: {len(fails)} problem(s) in the ticket index")
        return 1
    print(f"PASS: {len(rows)} tickets, every saved GitHub issue has one row, open/closed agrees; "
          f"backfill debt {debt_rows} rows (shrink-only)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
