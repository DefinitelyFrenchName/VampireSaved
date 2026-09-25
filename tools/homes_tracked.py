#!/usr/bin/env python3
"""homes_tracked.py — the close ritual's TRACKED-HOME check: every file a
session's findings table names as a finding's HOME or TEST must be a TRACKED
file (`git ls-files`), never a build/ artifact and never a name that resolves
nowhere. Promoted from the inline script of the 14z-181 close after
rule-checker runs 185-187 found FIVE build-only citations in one table (a
home of (j), the tests of (l), (w) and (gg), and the check's own script, which
lived in no file). Companion of tools/close_findings.py (addresses) — this one
sees FILE NAMES, not findings.

  python3 tools/homes_tracked.py "(12) THE FINDINGS TABLE" [--state STATE.md] [out]
  python3 tools/homes_tracked.py --newest            # the newest group's findings row

The row is the STATE.md table row whose first cell starts with the given text
(`--newest`: the first `THE FINDINGS TABLE` row in file order, the current
sitting's — what tests/test_close_tools.sh runs at every tier, so the output
file of a close is a SNAPSHOT (its header carries the row's fingerprint) and
the gate's live run is the check).
Five reads of its text: (1) every backticked token that names a file (has a
`/` or a code/doc extension) is resolved against `git ls-files` — a build/
path (outside build/manifest) or an unresolved name is a FAIL; (2) every
`build/...` path ANYWHERE in the row, backticked or in prose, is a FAIL (a
home in the untracked build dir); (2b) a document cited in prose by its bare
name (README, NEXT_SESSION, STATE, HANDOFF, the histories) or as a bare
name.ext outside backticks resolves to a tracked file or FAILs; (3) every test clause (the text after
`test` up to the next finding letter, parentheses included) that says
`artifact`, `.txt`, `.log` or `scratch` without a tracked path is listed for
REVIEW — prose can cite an
untracked file without a backtick, and only a reader can tell. A gate cited by its
stem (`test_x`, `audit_x`) resolves to tests/<stem>.sh; (1b) every ticket
cited as `#N` must have a row in docs/project/tickets.tsv whose answers cite
no build/ path and no untracked file, every answer link resolved by the
index's own grammar (`path` or `path § text`, root documents included) with a §
anchor's text required on some line of its file (an `../` input is out of tree
by rule and is listed, never failed). Tokens that name a
section, a control mode, a column or a memory note are listed under OTHER. EXIT 1 on any FAIL. `--selftest` plants a row with a
build/ prose citation, a backticked build/ token, an unresolved name, an
unresolved gate stem, a ticket with no index row, ticket rows citing a build/
file and an untracked file (a planted index), a prose-cited document that
resolves nowhere and a parenthesised clause saying scratch, and must catch each; `--blind` disables every build/ read, the ticket rows' included (a known-bad
variant that the self-test must FAIL on — test_close_tools' mode).
"""
import hashlib
import pathlib
import re
import subprocess
import sys

EXT = r"\.(md|py|sh|tsv|toml|txt|log|json|rpl)$"


def find_row(state, prefix):
    for line in pathlib.Path(state).read_text(encoding="utf-8").splitlines():
        if prefix == "--newest":
            if re.match(r"\| \*\*\(\d+\) THE FINDINGS TABLE\*\*", line):
                return line   # the first findings row in file order — the newest session group's
        elif line.startswith("| **" + prefix):
            return line
    sys.exit(f"no row starting with '| **{prefix}' in {state}")


DOCS = {"README": "README.md", "NEXT_SESSION": "docs/NEXT_SESSION.md", "STATE": "STATE.md", "STATE_HISTORY": "STATE_HISTORY.md",
        "DECISIONS_HISTORY": "DECISIONS_HISTORY.md", "HANDOFF": "HANDOFF.md", "GOTCHAS": "docs/GOTCHAS.md", "PROVENANCE": "docs/PROVENANCE.md"}
BLIND = False   # --blind: the build/ reads are disabled — a KNOWN-BAD variant for test_close_tools' mode


def check(row, tracked, tickets=None):
    out, fail = [], 0
    toks = sorted(set(re.findall(r"`([^`]+)`", row)))
    paths, other = [], []
    for t in toks:
        c = t.split(" ")[0].split("§")[0].strip()
        if re.fullmatch(r"(test|audit)_[a-z0-9_]+", c):
            c = "tests/" + c + ".sh"   # a gate cited by its stem
        if "/" in c or re.search(EXT, c):
            hits = sorted((p for p in tracked if p == c or p.endswith("/" + c)), key=lambda p: (p != c, p.count("/"), p))   # the exact path first, then the shallowest (run 205 prep: README.md named release/.../README.md)
            if c.startswith("build/") and not c.startswith("build/manifest") and not BLIND:
                st, fail = "FAIL untracked-build", fail + 1
            elif len(hits) > 1 and hits[0] != c:
                st, fail = f"FAIL ambiguous ({len(hits)} tracked files end in this name, none is it exactly)", fail + 1   # run 206 Q4: a name must resolve to ONE file
            elif hits:
                st = "TRACKED " + hits[0]
            else:
                st, fail = "FAIL not-in-ls-files", fail + 1
            paths.append(f"{st:60s} <- `{t}`")
        else:
            other.append(t)
    out.append(f"# (1) backticked file tokens: {len(paths)}, FAIL: {fail}")
    out += sorted(paths)
    # (1b) a home cited as a ticket number (**#N** or #N) must have a row in the tracked
    # index whose four answers cite no build/ path (rule-checker run 2026-09-25-189)
    if tickets is None:
        tickets = {}
        try:
            for line in pathlib.Path("docs/project/tickets.tsv").read_text(encoding="utf-8").splitlines():
                c = line.split("\t")
                if c and c[0].isdigit():
                    tickets[c[0]] = line
        except OSError:
            pass
    trows = []
    for n in sorted(set(re.findall(r"#(\d+)\b", row)), key=int):
        if n not in tickets:
            trows.append(f"{'FAIL ticket-not-in-index':60s} <- #{n}"); fail += 1
            continue
        cited = re.findall(r"(?<![\w])((?:\.\./|build/|docs/|tests/|tools/)[A-Za-z0-9_./-]+)", tickets[n])
        # every answer LINK too (tickets.tsv's own grammar: `path` or `path § text`, links
        # separated by ` ; `), root-level documents included, and a § anchor's text must be
        # on some line of the file — run 2026-09-25-201: a ticket row cited a DECISIONS_HISTORY
        # heading my own edit had renamed, and the path-prefix scan never saw a root document
        anchors = []
        for col in tickets[n].split("\t")[4:8]:
            for link in col.split(" ; "):
                link = link.strip()
                if not link or link == "none":
                    continue
                path, _, anchor = link.partition(" § ")
                path = path.strip().split(" ")[0]
                if re.search(r"\.(md|py|sh|tsv|toml|txt)$", path) or "/" in path:
                    cited.append(path)
                    if anchor:
                        anchors.append((path, anchor.strip()))
        bad = []
        for c in sorted(set(cited)):
            if c.startswith("../"):
                continue   # out of tree by rule (the frame-data pages): listed, never a FAIL
            if c.startswith("build/") and not c.startswith("build/manifest"):
                if not BLIND:
                    bad.append(c + " (build/)")
            elif not any(p == c or p.startswith(c.rstrip("/") + "/") for p in tracked):
                bad.append(c + " (not tracked)")
        for path, anchor in anchors:
            try:
                body = pathlib.Path(path).read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue   # the path itself is reported above
            if anchor not in body:
                bad.append(f"{path} § {anchor[:50]!r} (anchor on no line)")
        if bad:
            trows.append(f"{'FAIL ticket-row-cites-untracked':60s} <- #{n}: " + ", ".join(bad)); fail += 1
        else:
            oot = sorted(c for c in set(cited) if c.startswith("../"))
            trows.append(f"{'TICKET docs/project/tickets.tsv row':60s} <- #{n}" + (f" (out-of-tree input: {', '.join(oot)})" if oot else ""))
    out.append(f"# (1b) ticket homes: {len(trows)}, FAIL: {sum(1 for r in trows if r.startswith('FAIL'))}")
    out += trows
    prose = re.findall(r"build/[A-Za-z0-9_./-]+", row)
    seen = {t.split(" ")[0] for t in toks}
    prose = sorted(set(p for p in prose if not p.startswith("build/manifest") and p not in seen)) if not BLIND else []
    out.append(f"# (2) build/ paths anywhere in the row (prose or code): {len(prose)}" + (" — FAIL" if prose else ""))
    out += ["FAIL untracked-build (prose)                                 <- " + p for p in prose]
    fail += len(prose)
    # (2b) a document cited in PROSE by its bare name — the project's named documents
    # (README, NEXT_SESSION, STATE row (9), HANDOFF ...) and any bare name.ext outside
    # backticks — resolves to a tracked file or FAILs (rule-checker run 2026-09-25-190)
    bare = re.sub(r"`[^`]*`", " ", row)
    docs_ = []
    for name in sorted(set(re.findall(r"\b(README|NEXT_SESSION|STATE_HISTORY|DECISIONS_HISTORY|STATE|HANDOFF|GOTCHAS|PROVENANCE)\b", bare))):
        path = DOCS[name]
        st = "TRACKED " + path if path in tracked else "FAIL not-in-ls-files"
        docs_.append(f"{st:60s} <- {name} (prose)")
        fail += st.startswith("FAIL")
    for name in sorted(set(re.findall(r"(?<![\w/`])([A-Za-z0-9_-]+\.(?:md|py|sh|tsv|toml|txt|log))\b", bare))):
        hits = sorted((p for p in tracked if p == name or p.endswith("/" + name)), key=lambda p: (p != name, p.count("/"), p))   # the exact path first, then the shallowest
        st = (f"FAIL ambiguous ({len(hits)} tracked files end in this name, none is it exactly)" if len(hits) > 1 and hits[0] != name
              else "TRACKED " + hits[0] if hits else "FAIL not-in-ls-files")   # run 206 Q4: a name must resolve to ONE file
        docs_.append(f"{st:60s} <- {name} (prose)")
        fail += st.startswith("FAIL")
    out.append(f"# (2b) documents cited in prose by bare name: {len(docs_)}, FAIL: {sum(1 for d in docs_ if d.startswith('FAIL'))}")
    out += docs_
    review = []
    for m in re.finditer(r"test[s]?[:'s]*\s(.*?)(?=\s\([a-z]{1,2}\)\s|\s\*\*\([a-z]{1,2}\)|\s\|\s*$|$)", row):
        clause = m.group(1)
        if re.search(r"artifact|\.txt|\.log|scratch", clause) and not re.search(r"`[^`]*\.(sh|py)`|`(test|audit)_[a-z_]+`", clause):
            review.append(clause[:140])
    out.append(f"# (3) test clauses citing an artifact/.txt/.log/scratch with no tracked script: {len(review)} for REVIEW")
    out += ["REVIEW <- " + r for r in review]
    out.append("# OTHER (sections, modes, columns, gate stems, memories): " + " | ".join(other))
    return out, fail


def main():
    global BLIND
    a = sys.argv[1:]
    if "--blind" in a:
        BLIND = True; a.remove("--blind")
    tracked = set(subprocess.run(["git", "ls-files"], capture_output=True, text=True).stdout.split("\n"))
    if a and a[0] == "--selftest":
        row = "| **(0) SELFTEST** | (a) x — home `docs/README.md`; test `test_docshape`. (b) y — home the table in build/agent0/table.txt; test `build/agent0/probe.log`. (c) z — home `nowhere_at_all.md`; test `test_no_such_gate_zq`. (d) w — home **#0**; test: none yet (the probe was scratch, not promoted). (e) v — home README and the note in nowhere_doc_zq.md; test: none. (f) u — home `packet.md` and the page manifest.tsv; test: none. |"
        row = row.replace("home **#0**", "home **#0**, **#900001**, **#900002**, **#900003** and **#900004**")
        planted = {"900001": "900001\tbug\topen\tclean\ttests/test_docshape.sh\tnone\tdocs/README.md\tnone\t14z-0",
                   "900002": "900002\tbug\topen\tcites build\tbuild/agent0/census.txt\tnone\tdocs/README.md\tnone\t14z-0",
                   "900003": "900003\tbug\topen\tcites untracked\ttools/no_such_tool_zq.py\tnone\tdocs/README.md\tnone\t14z-0",
                   "900004": "900004\tbug\topen\tstale anchor\ttests/test_docshape.sh\tDECISIONS_HISTORY.md § zq no such heading anywhere\tnone\tnone\t14z-0"}
        out, fail = check(row, tracked, planted)
        print("\n".join(out))
        want = ("FAIL untracked-build " in "\n".join(out), "FAIL untracked-build (prose)" in "\n".join(out), "FAIL not-in-ls-files" in "\n".join(out), any(l.startswith("REVIEW") for l in out))
        stem_ok = any("TRACKED tests/test_docshape.sh" in l for l in out) and any("not-in-ls-files" in l and "test_no_such_gate_zq" in l for l in out)
        ticket_ok = (any("ticket-not-in-index" in l and l.endswith("#0") for l in out) and any(l.startswith("TICKET") and "#900001" in l for l in out)
                     and any("ticket-row-cites-untracked" in l and "#900002" in l and "(build/)" in l for l in out)
                     and any("ticket-row-cites-untracked" in l and "#900003" in l and "(not tracked)" in l for l in out)
                     and any("ticket-row-cites-untracked" in l and "#900004" in l and "anchor on no line" in l for l in out))
        prose_ok = any("TRACKED README.md" in l and "(prose)" in l for l in out) and any("not-in-ls-files" in l and "nowhere_doc_zq.md (prose)" in l for l in out)
        ambig_ok = any("FAIL ambiguous" in l and l.endswith("<- `packet.md`") for l in out) and any("FAIL ambiguous" in l and "manifest.tsv (prose)" in l for l in out)
        ok = all(want) and stem_ok and ticket_ok and prose_ok and ambig_ok and fail == 11
        print("SELFTEST " + ("PASS: the backticked build/ token, the prose build/ path, the unresolved name, the unresolved gate stem, the ticket with no index row, the ticket rows citing a build/ file, an untracked file and a § anchor on no line, the prose-cited document that resolves nowhere, the parenthesised scratch-citing test clause and a backticked and a prose name that end two or more tracked files but are none of them exactly are each caught; the real gate stem, the clean ticket and the prose-cited README resolve" if ok else f"FAIL: {want} stem={stem_ok} ticket={ticket_ok} prose={prose_ok} ambiguous={ambig_ok} fail={fail}"))
        sys.exit(0 if ok else 1)
    state = "STATE.md"
    if "--state" in a:
        i = a.index("--state"); state = a[i + 1]; del a[i:i + 2]
    prefix = a[0]
    row = find_row(state, prefix)
    out, fail = check(row, tracked)
    fp = hashlib.sha1(row.encode("utf-8")).hexdigest()[:12]
    out.insert(0, f"# homes_tracked.py — row '{prefix}' of {state} ({row[:60]!r}...): every file named as a home or test checked against git ls-files; FAIL {fail}; ROW FINGERPRINT {fp} (sha1 of the row's text — an output whose fingerprint differs from a fresh run's was made on another row; the gate re-runs the tool on the newest row at every tier)")
    text = "\n".join(out) + "\n"
    if len(a) > 1:
        pathlib.Path(a[1]).write_text(text, encoding="utf-8")
    sys.stdout.write(text)
    sys.exit(1 if fail else 0)


if __name__ == "__main__":
    main()
