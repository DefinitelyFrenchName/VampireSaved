#!/usr/bin/env python3
"""rulecheck.py — the independent adversarial RULE-CHECKER at a decision point
(GitHub #152, the maintainer's proposal of 14z-159; built 14z-163).

WHAT IT IS. Before a measurement becomes the basis for an action — a manifest
change on the strength of a measurement, a freeze, a frozen or re-frozen
expectation, or a recommendation to the maintainer — the working agent hands
the ARTIFACTS (never a narrative) to a FRESH agent that answers five fixed
questions with a structured verdict. Redundancy for rule APPLICATION, the way
a second emulator is redundancy for a measurement. The failure it exists to
catch: a rule that is loaded and cited but not applied at the moment a result
looks strongest (14z-159: a 6851/6851-identical comparison whose two legs
shared a poke path; 14z-162: a maintainer decision inferred from a timestamp).

THE PROTOCOL, and every condition is load-bearing (docs/project/rule_checker.md):
  1. ARTIFACTS ONLY. The packet is the decision kind, ONE claim sentence and a
     list of repo-relative paths. The checker reads the files itself.
  2. A SHORT CHECKLIST — the five questions, read from the document of record
     (docs/project/rule_checker.md, between the CHECKLIST markers), never a copy.
  3. STRUCTURED OUTPUT. Six lines: `Q1..Q5: VIOLATED|OK|N-A — <evidence>` and
     `VERDICT: VIOLATED|OK`. `record` REFUSES prose.
  4. MUST-FIRE. Every real run is PAIRED with a planted known violation (a
     fixture under tests/rulecheck/fixtures/) run BLIND by a second fresh
     agent — the two prompts are labelled a/b at random, so neither agent knows
     which is the plant. A plant that is not caught VOIDS the real verdict.
     Every fixture is CALIBRATED (proven catchable) before it may serve as a
     plant; a negative fixture (expected OK) proves the checker stays quiet.
  5. BINDING. A VIOLATED verdict stops the action (`record` exits 1) until a
     resolution is recorded; the verdict text is kept verbatim in the run dir
     and reported verbatim, never summarised. A freeze is bound mechanically:
     every registry row after the checker's birth needs a `freeze` ledger row.

THE LEDGER: tests/rulecheck/ledger.tsv, one row per run (append-only). THE RUN
DIR: tests/rulecheck/runs/<id>/ — packet.md, manifest.tsv (artifact sha1s),
control.txt (the plant and its slot), verdict_real.txt, verdict_control.txt.
STAGING (untracked): build/rulecheck/<id>/{a,b}/ with the prompts.

Usage:
  python3 tools/rulecheck.py fixtures
  python3 tools/rulecheck.py prepare --decision KIND --subject TEXT --claim "..." \
          --artifact PATH[:FIRST-LAST] ... [--session 14z-N] [--model NAME] [--id ID]
  python3 tools/rulecheck.py prepare --calibrate FIXTURE [--session 14z-N] [--model NAME]
  python3 tools/rulecheck.py record ID --a FILE --b FILE      # the two agents' final messages, verbatim
  python3 tools/rulecheck.py resolve ID --how "..."           # after a VIOLATED
  python3 tools/rulecheck.py check [--root DIR]               # the gate's logic
  python3 tools/rulecheck.py --selftest                       # the parser's fixtures
"""
import argparse
import datetime as _dt
import hashlib
import os
import random
import re
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DOC = "docs/project/rule_checker.md"
LEDGER = "tests/rulecheck/ledger.tsv"
RUNS = "tests/rulecheck/runs"
FIXTURES = "tests/rulecheck/fixtures"
REGISTRY = "tests/expected/registry.tsv"
STAGING = "build/rulecheck"
# THE BIRTH: the last registry row when the checker was born (merged-m18,
# 14z-144). Every registry row AFTER it needs a `freeze` ledger row naming its
# expectation set (rulecheck check, section 5).
BIRTH_REGISTRY_KEY = "00f9cf1360c5720f48ff7e33906b97f25bcc48d0"
DECISIONS = ("build", "freeze", "expectation", "recommendation", "calibration")
QUESTIONS = ("Q1", "Q2", "Q3", "Q4", "Q5")
LEDGER_COLS = ("id", "date", "session", "decision", "subject", "control",
               "control_verdict", "verdict", "violated", "resolution", "model")
CHECKLIST_BEGIN = "<!-- CHECKLIST BEGIN -->"
CHECKLIST_END = "<!-- CHECKLIST END -->"

Q_RE = re.compile(r"^(Q[1-5]): (VIOLATED|OK|N-A) — (.+\S)$")
V_RE = re.compile(r"^VERDICT: (VIOLATED|OK)$")


def die(msg, rc=1):
    print(f"FAIL: {msg}")
    sys.exit(rc)


def sha1(p: Path) -> str:
    return hashlib.sha1(p.read_bytes()).hexdigest()


# ---------------------------------------------------------------- the verdict
def parse_verdict(text: str):
    """Return (answers: dict Qn -> (state, evidence), verdict) or raise ValueError.

    Exactly six lines of substance: Q1..Q5 in order, then VERDICT. A code fence
    line (```) is tolerated and dropped; any other non-empty line is PROSE and
    refused — a prose verdict is unfalsifiable and gets rationalised away.
    """
    lines = [ln.rstrip() for ln in text.splitlines()]
    lines = [ln for ln in lines if ln.strip() and not ln.strip().startswith("```")]
    if len(lines) != 6:
        raise ValueError(f"expected exactly 6 lines of substance (Q1..Q5, VERDICT), got {len(lines)}")
    answers = {}
    for i, q in enumerate(QUESTIONS):
        m = Q_RE.match(lines[i])
        if not m or m.group(1) != q:
            raise ValueError(f"line {i + 1} is not `{q}: VIOLATED|OK|N-A — <evidence>`: {lines[i][:80]!r}")
        answers[q] = (m.group(2), m.group(3))
    m = V_RE.match(lines[5])
    if not m:
        raise ValueError(f"line 6 is not `VERDICT: VIOLATED|OK`: {lines[5][:80]!r}")
    verdict = m.group(1)
    any_v = any(s == "VIOLATED" for s, _ in answers.values())
    if (verdict == "VIOLATED") != any_v:
        raise ValueError("VERDICT disagrees with the answers (VIOLATED iff any question is VIOLATED)")
    return answers, verdict


def violated_list(answers):
    return [q for q in QUESTIONS if answers[q][0] == "VIOLATED"]


# ---------------------------------------------------------------- the packet
def read_checklist(root: Path) -> str:
    doc = (root / DOC).read_text()
    if CHECKLIST_BEGIN not in doc or CHECKLIST_END not in doc:
        die(f"{DOC} carries no CHECKLIST markers")
    return doc.split(CHECKLIST_BEGIN, 1)[1].split(CHECKLIST_END, 1)[0].strip()


def read_expect(fx: Path):
    """EXPECT: `VIOLATED Q3 Q4` (caught when the verdict is VIOLATED on at least
    one of the named questions) or `OK` (a negative fixture: must come out OK)."""
    toks = (fx / "EXPECT").read_text().split()
    if not toks:
        die(f"{fx.name}: empty EXPECT")
    if toks[0] == "OK" and len(toks) == 1:
        return ("OK", [])
    if toks[0] == "VIOLATED" and len(toks) > 1 and all(t in QUESTIONS for t in toks[1:]):
        return ("VIOLATED", toks[1:])
    die(f"{fx.name}: EXPECT must be `OK` or `VIOLATED Qn...`, got {toks}")


def list_fixtures(root: Path):
    fdir = root / FIXTURES
    out = []
    for fx in sorted(p for p in fdir.iterdir() if p.is_dir()):
        for need in ("packet.md", "EXPECT", "files"):
            if not (fx / need).exists():
                die(f"fixture {fx.name} lacks {need}")
        out.append((fx.name, read_expect(fx)))
    if not out:
        die("no fixtures")
    return out


def packet_text(decision, subject, claim, artifacts):
    lines = ["THE PACKET", "",
             f"Decision kind: {decision}",
             f"Subject: {subject}",
             f"Claim (the working agent's sentence): {claim}",
             "Artifacts (read every one, in full):"]
    for a in artifacts:
        lines.append(f"  - {a}")
    return "\n".join(lines) + "\n"


def caught(expect, answers, verdict):
    kind, qs = expect
    if kind == "OK":
        return verdict == "OK"
    return verdict == "VIOLATED" and any(answers[q][0] == "VIOLATED" for q in qs)


def prompt_text(root: Path, packet: str, staged_root: str) -> str:
    return (
        "You are an independent rule-checker for a software project. You have no context beyond this "
        "message and the files it names, and that is the point: you must not inherit anyone's framing. "
        "Your only job is to answer the five questions below about ONE proposed action, from the ARTIFACTS, "
        f"never from the claim. Read every named file yourself, in full, with your file tools; paths are "
        f"relative to {staged_root}. Assume the person who wrote the claim is competent and wrong in a way "
        "that looks right. Where the claim says something the artifacts do not show, that is a finding. Do "
        "not run anything; do not modify anything; do not look outside the named files.\n\n"
        + packet + "\n" + read_checklist(root) + "\n"
    )


def stage_artifacts(root: Path, src_specs, dst: Path):
    """Copy each artifact (or a line range of it) under dst, keeping its path.
    Returns [(display path, sha1 of the staged copy)]."""
    out = []
    for spec in src_specs:
        path, _, rng = spec.partition(":")
        src = root / path
        if not src.is_file():
            die(f"artifact not found: {path}")
        rel = Path(path)
        target = dst / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        if rng:
            a, b = rng.split("-")
            lines = src.read_text(errors="replace").splitlines(keepends=True)
            target.write_text("".join(lines[int(a) - 1:int(b)]))
            disp = f"{rel} (lines {a}-{b})"
        else:
            shutil.copy2(src, target)
            disp = str(rel)
        out.append((disp, sha1(target), str(rel)))
    return out


def cmd_prepare(a):
    root = REPO
    ledger_rows = read_ledger(root)
    fixtures = list_fixtures(root)
    session = a.session or "-"
    model = a.model or "default"
    today = _dt.date.today().isoformat()
    n = max(len(ledger_rows), len([p for p in (root / RUNS).glob(f"{today}-*") if p.is_dir()]) if (root / RUNS).exists() else 0)
    rid = a.id or f"{today}-{n + 1:02d}"
    rdir = root / RUNS / rid
    if rdir.exists():
        die(f"run {rid} exists")
    stage = root / STAGING / rid
    if stage.exists():
        shutil.rmtree(stage)

    if a.calibrate:
        names = [n for n, _ in fixtures]
        if a.calibrate not in names:
            die(f"unknown fixture {a.calibrate}; have {names}")
        fx = root / FIXTURES / a.calibrate
        real_packet = (fx / "packet.md").read_text()
        real_src = fx / "files"
        decision, subject, claim = "calibration", a.calibrate, "(the fixture's packet)"
        expect_kind = dict(fixtures)[a.calibrate][0]
        if expect_kind == "OK":
            # a NEGATIVE fixture is calibrated beside a PLANT (a calibrated positive), blind,
            # so a reader quiet because it is dead cannot read as a clean packet (run 08, Q4)
            eligible = [n for n, ex in fixtures if ex[0] == "VIOLATED" and calibrated(ledger_rows, n)]
            if not eligible:
                die("a negative fixture is calibrated beside a plant — calibrate a positive fixture first")
            control_name = eligible[len(ledger_rows) % len(eligible)]
        else:
            control_name = a.calibrate
    else:
        if not (a.decision and a.subject and a.claim and a.artifact):
            die("prepare needs --decision --subject --claim and at least one --artifact")
        if a.decision not in DECISIONS[:-1]:
            die(f"--decision must be one of {DECISIONS[:-1]}")
        decision, subject, claim = a.decision, a.subject, a.claim
        real_packet = None
        # the plant, by rotation over the calibrated fixtures, positive ones only
        eligible = [n for n, ex in fixtures if ex[0] == "VIOLATED" and calibrated(ledger_rows, n)]
        if not eligible:
            die("no CALIBRATED positive fixture to plant — run `prepare --calibrate <fixture>` first")
        control_name = eligible[len(ledger_rows) % len(eligible)]

    # slots: which of a/b carries the plant is drawn at random and recorded
    rng = random.SystemRandom()
    control_slot = rng.choice("ab")
    real_slot = "b" if control_slot == "a" else "a"
    rdir.mkdir(parents=True)
    (stage / "a").mkdir(parents=True)
    (stage / "b").mkdir(parents=True)

    # the REAL packet (or, when calibrating, the fixture as the real packet)
    if a.calibrate:
        shutil.copytree(real_src, stage / real_slot, dirs_exist_ok=True)
        real_text = real_packet
        manifest = [(str(p.relative_to(real_src)), sha1(p), str(p.relative_to(real_src)))
                    for p in sorted(real_src.rglob("*")) if p.is_file()]
    else:
        manifest = stage_artifacts(root, a.artifact, stage / real_slot)
        real_text = packet_text(decision, subject, claim, [d for d, _, _ in manifest])
    (rdir / "packet.md").write_text(real_text)
    with (rdir / "manifest.tsv").open("w") as f:
        f.write("# artifact\tsha1 (of the staged copy, at prepare time)\n")
        for disp, h, _ in manifest:
            f.write(f"{disp}\t{h}\n")

    # the CONTROL packet: the plant's files copied under the other slot
    if a.calibrate and control_name == a.calibrate:
        # a POSITIVE fixture is calibrated alone: the control slot mirrors the real
        # slot (one agent is enough; pass its output as both --a and --b)
        shutil.copytree(real_src, stage / control_slot, dirs_exist_ok=True)
        control_text = real_text
    else:
        fx = root / FIXTURES / control_name
        shutil.copytree(fx / "files", stage / control_slot, dirs_exist_ok=True)
        control_text = (fx / "packet.md").read_text()
    (rdir / "control.txt").write_text(f"fixture\t{control_name}\nslot\t{control_slot}\n")

    for slot, text in ((real_slot, real_text), (control_slot, control_text)):
        (stage / f"prompt_{slot}.md").write_text(prompt_text(root, text, str(stage / slot)))
    (rdir / "meta.tsv").write_text(
        f"decision\t{decision}\nsubject\t{subject}\nsession\t{session}\nmodel\t{model}\nclaim\t{claim}\n")
    print(f"prepared run {rid}")
    print(f"  prompts: {stage}/prompt_a.md and {stage}/prompt_b.md")
    print("  spawn TWO FRESH agents (never a fork) in one message, one per prompt, each prompt verbatim")
    print(f"  and nothing else; save each agent's final message verbatim, then:")
    print(f"  python3 tools/rulecheck.py record {rid} --a <file> --b <file>")
    if a.calibrate and control_name == a.calibrate:
        print(f"  (calibration of {control_name}: one agent on prompt_{real_slot}.md is enough; pass the same file as --a and --b)")
    elif a.calibrate:
        print(f"  (calibration of the negative {a.calibrate} beside the plant {control_name}: two agents, blind)")


def calibrated(ledger_rows, name):
    """A positive fixture: a calibration row where it was itself caught. A negative
    fixture: a calibration row where it read OK beside a CAUGHT plant (or, before
    plants were paired, alone)."""
    for r in ledger_rows:
        if r["decision"] != "calibration" or r["subject"] != name or r["control_verdict"] != "CAUGHT":
            continue
        if r["control"] == name or r["verdict"] == "OK":
            return True
    return False


# ---------------------------------------------------------------- the ledger
def read_ledger(root: Path):
    p = root / LEDGER
    rows = []
    if not p.exists():
        return rows
    for ln in p.read_text().splitlines():
        if not ln.strip() or ln.startswith("#") or ln.startswith("id\t"):
            continue  # comments and the column-name line
        cols = ln.split("\t")
        if len(cols) != len(LEDGER_COLS):
            die(f"{LEDGER}: a row has {len(cols)} columns, not {len(LEDGER_COLS)}: {ln[:60]!r}")
        rows.append(dict(zip(LEDGER_COLS, cols)))
    return rows


def append_ledger(root: Path, row):
    p = root / LEDGER
    if not p.exists():
        die(f"{LEDGER} is missing")
    with p.open("a") as f:
        f.write("\t".join(row[c] for c in LEDGER_COLS) + "\n")


def read_kv(p: Path):
    d = {}
    for ln in p.read_text().splitlines():
        if "\t" in ln:
            k, v = ln.split("\t", 1)
            d[k] = v
    return d


def cmd_record(a):
    root = REPO
    rdir = root / RUNS / a.id
    if not rdir.is_dir():
        die(f"no run {a.id}")
    if (rdir / "verdict_real.txt").exists():
        die(f"run {a.id} is already recorded")
    meta = read_kv(rdir / "meta.tsv")
    ctl = read_kv(rdir / "control.txt")
    texts = {"a": Path(a.a).read_text(), "b": Path(a.b).read_text()}
    parsed = {}
    for slot, t in texts.items():
        try:
            parsed[slot] = parse_verdict(t)
        except ValueError as e:
            die(f"slot {slot}: the output is not a structured verdict — {e}. Prose is refused; ask the agent for the six lines.")
    control_slot = ctl["slot"]
    real_slot = "b" if control_slot == "a" else "a"
    expect = read_expect(root / FIXTURES / ctl["fixture"])
    calibration = meta["decision"] == "calibration"
    self_cal = calibration and ctl["fixture"] == meta["subject"]
    if self_cal:
        # the fixture is in BOTH slots; the verdict under test is the real slot's
        c_ans, c_ver = parsed[real_slot]
    else:
        c_ans, c_ver = parsed[control_slot]
    r_ans, r_ver = parsed[real_slot]
    plant_caught = caught(expect, c_ans, c_ver)
    if calibration and not self_cal:
        # a negative fixture beside a plant: the plant must be caught AND the subject must read as expected
        subj_expect = read_expect(root / FIXTURES / meta["subject"])
        subject_ok = caught(subj_expect, r_ans, r_ver)
    (rdir / "verdict_real.txt").write_text(texts[real_slot])
    (rdir / "verdict_control.txt").write_text(texts[control_slot])
    row = dict(id=a.id, date=_dt.date.today().isoformat(), session=meta["session"],
               decision=meta["decision"], subject=meta["subject"], control=ctl["fixture"],
               control_verdict="CAUGHT" if plant_caught else "DEAD",
               verdict=(r_ver if plant_caught else "VOID"),
               violated=(" ".join(violated_list(r_ans)) or "-"),
               resolution="-", model=meta["model"])
    for c in LEDGER_COLS:
        if "\t" in row[c] or "\n" in row[c]:
            die(f"ledger field {c} carries a tab or newline")
    append_ledger(root, row)
    print(f"== rulecheck {a.id} ({meta['decision']}: {meta['subject']}) ==")
    print(f"plant: {ctl['fixture']} in slot {control_slot} — {'CAUGHT' if plant_caught else 'DEAD'}"
          f" (expected {expect[0]} {' '.join(expect[1])})")
    if calibration and not self_cal:
        print("--- the negative's verdict (verbatim) ---")
        print(texts[real_slot].rstrip())
        if not plant_caught:
            print(f"CONTROL DEAD: the plant {ctl['fixture']} was not caught — this calibration is VOID.")
            print("--- plant output (verbatim) ---"); print(texts[control_slot].rstrip())
            sys.exit(2)
        if subject_ok:
            print(f"CALIBRATED: the negative {meta['subject']} read OK beside a caught plant.")
            return
        print(f"CALIBRATION FAILED: the negative {meta['subject']} read {r_ver} on {' '.join(violated_list(r_ans)) or '-'} — read the evidence: a real gap in the packet, or checker noise.")
        sys.exit(2)
    if calibration:
        # a calibration proves the FIXTURE: the expected verdict came back, or it did not
        print("--- verdict (verbatim) ---")
        print(texts[real_slot].rstrip())
        if plant_caught:
            print(f"CALIBRATED: {ctl['fixture']} returns its expected verdict; it may serve as a plant (or, negative, proves the checker quiet).")
            return
        print(f"CALIBRATION FAILED: {ctl['fixture']} expected {expect[0]} {' '.join(expect[1])} and got {c_ver} on {' '.join(violated_list(c_ans)) or '-'}."
              " A positive fixture the checker misses is not a plant; a negative fixture it flags is either checker noise or a real gap in the packet — read the evidence before deciding which.")
        sys.exit(2)
    if not plant_caught:
        print("CONTROL DEAD: the planted violation was not caught — the real verdict is VOID and licenses nothing.")
        print("  Do not proceed on this run. Re-run with fresh agents; if the plant is never caught, the checker is dead, not the plant.")
        print("--- control output (verbatim) ---")
        print(texts[control_slot].rstrip())
        sys.exit(2)
    print("--- real verdict (verbatim; report it as is, never summarised) ---")
    print(texts[real_slot].rstrip())
    if r_ver == "VIOLATED":
        print(f"VIOLATED on {' '.join(violated_list(r_ans))}: the action STOPS until `rulecheck resolve {a.id} --how ...` records what changed.")
        sys.exit(1)
    print("OK: no question violated; the action may proceed.")


def cmd_resolve(a):
    root = REPO
    rows = read_ledger(root)
    hit = [r for r in rows if r["id"] == a.id]
    if not hit:
        die(f"no ledger row {a.id}")
    r = hit[0]
    if r["verdict"] != "VIOLATED":
        die(f"run {a.id} is {r['verdict']}, not VIOLATED — nothing to resolve")
    if r["resolution"] != "-":
        die(f"run {a.id} is already resolved")
    if "\t" in a.how or "\n" in a.how or not a.how.strip():
        die("--how must be one non-empty line")
    p = root / LEDGER
    lines = p.read_text().splitlines(keepends=True)
    out = []
    for ln in lines:
        if not ln.startswith("#") and ln.split("\t")[0] == a.id:
            cols = ln.rstrip("\n").split("\t")
            cols[LEDGER_COLS.index("resolution")] = a.how.strip()
            ln = "\t".join(cols) + "\n"
        out.append(ln)
    p.write_text("".join(out))
    print(f"resolved {a.id}: {a.how.strip()}")


# ---------------------------------------------------------------- the check
def cmd_check(root: Path) -> int:
    bad = 0

    def fail(msg):
        nonlocal bad
        bad += 1
        print(f"  FAIL: {msg}")

    print("== 1. the checklist of record and the fixtures are well-formed ==")
    checklist = read_checklist(root)
    for q in QUESTIONS:
        if not re.search(rf"^{q}\b", checklist, re.M):
            fail(f"{DOC}: the checklist lacks {q}")
    if "VERDICT:" not in checklist:
        fail(f"{DOC}: the checklist does not state the VERDICT line")
    fixtures = list_fixtures(root)
    pos = [n for n, ex in fixtures if ex[0] == "VIOLATED"]
    neg = [n for n, ex in fixtures if ex[0] == "OK"]
    print(f"  fixtures: {len(pos)} positive ({', '.join(pos)}), {len(neg)} negative ({', '.join(neg) or 'none'})")
    if not pos:
        fail("no positive fixture (a known violation to plant)")
    if not neg:
        fail("no negative fixture (a clean packet the checker must leave OK)")

    print("== 2. the ledger: every row well-formed, its run dir complete, its verdict files structured ==")
    rows = read_ledger(root)
    ids = [r["id"] for r in rows]
    if len(ids) != len(set(ids)):
        fail("duplicate run id in the ledger")
    for r in rows:
        rdir = root / RUNS / r["id"]
        if r["decision"] not in DECISIONS:
            fail(f"{r['id']}: decision {r['decision']!r} is not one of {DECISIONS}")
        if r["control_verdict"] not in ("CAUGHT", "DEAD"):
            fail(f"{r['id']}: control_verdict {r['control_verdict']!r}")
        if r["verdict"] not in ("OK", "VIOLATED", "VOID"):
            fail(f"{r['id']}: verdict {r['verdict']!r}")
        for need in ("packet.md", "manifest.tsv", "control.txt", "meta.tsv", "verdict_real.txt", "verdict_control.txt"):
            if not (rdir / need).is_file():
                fail(f"{r['id']}: run dir lacks {need}")
                continue
        for vf in ("verdict_real.txt", "verdict_control.txt"):
            p = rdir / vf
            if not p.is_file():
                continue
            try:
                ans, ver = parse_verdict(p.read_text())
            except ValueError as e:
                fail(f"{r['id']}/{vf}: not a structured verdict — {e}")
                continue
            if vf == "verdict_real.txt" and r["control_verdict"] == "CAUGHT":
                if ver != r["verdict"]:
                    fail(f"{r['id']}: ledger verdict {r['verdict']} but verdict_real.txt reads {ver}")
                vl = " ".join(violated_list(ans)) or "-"
                if vl != r["violated"]:
                    fail(f"{r['id']}: ledger violated {r['violated']!r} but the verdict file reads {vl!r}")
            if vf == "verdict_control.txt" and (rdir / "control.txt").is_file():
                ctl = read_kv(rdir / "control.txt")
                fxd = root / FIXTURES / ctl.get("fixture", "")
                if not fxd.is_dir():
                    fail(f"{r['id']}: control fixture {ctl.get('fixture')!r} does not exist")
                    continue
                if r["decision"] == "calibration" and ctl.get("fixture") == r["subject"]:
                    continue  # a self-calibration: the fixture is in both slots; the real slot carries the verdict
                exp = read_expect(fxd)
                c = caught(exp, ans, ver)
                if c != (r["control_verdict"] == "CAUGHT"):
                    fail(f"{r['id']}: verdict_control.txt says the plant was {'CAUGHT' if c else 'DEAD'} but the ledger says {r['control_verdict']}")
        if r["control_verdict"] == "DEAD" and r["verdict"] != "VOID":
            fail(f"{r['id']}: a DEAD plant must VOID the verdict (reads {r['verdict']})")
        if r["verdict"] == "VIOLATED" and r["resolution"] == "-" and r["decision"] != "calibration":
            fail(f"{r['id']}: VIOLATED with no resolution — the action it stopped is still stopped")
    print(f"  {len(rows)} rows")

    print("== 3. every fixture is CALIBRATED — proven catchable (or, negative, proven quiet) ==")
    for n, ex in fixtures:
        cal = [r for r in rows if r["decision"] == "calibration" and r["subject"] == n]
        ok = [r for r in cal if r["control_verdict"] == "CAUGHT"]
        if not ok:
            fail(f"fixture {n}: no CAUGHT calibration row — an uncalibrated plant proves nothing")
        else:
            print(f"  {n}: {len(ok)}/{len(cal)} calibrations caught")

    print("== 4. no real run rests on a DEAD plant, and the plant rotates ==")
    real = [r for r in rows if r["decision"] != "calibration"]
    dead = [r["id"] for r in real if r["control_verdict"] == "DEAD"]
    if dead:
        print(f"  note: {len(dead)} real run(s) voided by a dead plant: {', '.join(dead)} (allowed; each is VOID)")
    print(f"  {len(real)} real runs")

    print("== 5. every freeze since the checker's birth was checked ==")
    reg = root / REGISTRY
    keys = []
    for ln in reg.read_text().splitlines():
        if ln.strip() and not ln.startswith("#"):
            cols = ln.split("\t")
            keys.append((cols[0], cols[1] if len(cols) > 1 else "?"))
    idx = [i for i, (k, _) in enumerate(keys) if k == BIRTH_REGISTRY_KEY]
    if not idx:
        fail(f"{REGISTRY}: the birth key {BIRTH_REGISTRY_KEY[:8]} is not a row")
    else:
        after = keys[idx[0] + 1:]
        freeze_subjects = " ".join(r["subject"] for r in real if r["decision"] == "freeze" and r["verdict"] == "OK")
        for _, name in after:
            if not re.search(rf"(^|\s){re.escape(name)}(\s|$)", freeze_subjects):
                fail(f"registry row {name} was frozen with no OK `freeze` rulecheck row naming it")
        print(f"  {len(after)} registry rows after the birth")
    return bad


# ---------------------------------------------------------------- selftest
def selftest() -> int:
    good = ("Q1: OK — tests/x.sh:12\nQ2: N-A — no behavioural conclusion\nQ3: VIOLATED — \"both legs poke\"\n"
            "Q4: OK — control unpinned-level\nQ5: N-A — none attributed\nVERDICT: VIOLATED\n")
    cases = [
        ("well-formed", good, True),
        ("fenced", "```\n" + good + "```\n", True),
        ("prose preamble", "Here is my assessment.\n" + good, False),
        ("missing verdict", "\n".join(good.splitlines()[:5]) + "\n", False),
        ("verdict disagrees", good.replace("VERDICT: VIOLATED", "VERDICT: OK"), False),
        ("wrong order", good.replace("Q1:", "Q9:"), False),
        ("no evidence", good.replace("Q1: OK — tests/x.sh:12", "Q1: OK —"), False),
        ("hyphen not dash", good.replace("Q1: OK — ", "Q1: OK - "), False),
    ]
    bad = 0
    for name, text, ok in cases:
        try:
            parse_verdict(text)
            got = True
        except ValueError:
            got = False
        if got != ok:
            bad += 1
            print(f"  selftest WRONG: {name} parsed={got} expected={ok}")
    a, v = parse_verdict(good)
    if violated_list(a) != ["Q3"] or v != "VIOLATED":
        bad += 1
        print("  selftest WRONG: violated_list")
    if not caught(("VIOLATED", ["Q3", "Q4"]), a, v) or caught(("VIOLATED", ["Q1"]), a, v) or caught(("OK", []), a, v):
        bad += 1
        print("  selftest WRONG: caught()")
    print(f"selftest: {len(cases)} fixtures, {bad} wrong")
    return bad


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--selftest", action="store_true")
    sub = ap.add_subparsers(dest="cmd")
    sub.add_parser("fixtures")
    p = sub.add_parser("prepare")
    p.add_argument("--decision"); p.add_argument("--subject"); p.add_argument("--claim")
    p.add_argument("--artifact", action="append")
    p.add_argument("--calibrate"); p.add_argument("--session"); p.add_argument("--model"); p.add_argument("--id")
    r = sub.add_parser("record"); r.add_argument("id"); r.add_argument("--a", required=True); r.add_argument("--b", required=True)
    s = sub.add_parser("resolve"); s.add_argument("id"); s.add_argument("--how", required=True)
    c = sub.add_parser("check"); c.add_argument("--root", default=str(REPO))
    a = ap.parse_args()
    if a.selftest:
        return 1 if selftest() else 0
    if a.cmd == "fixtures":
        for n, ex in list_fixtures(REPO):
            print(f"{n}\t{ex[0]} {' '.join(ex[1])}".rstrip())
        return 0
    if a.cmd == "prepare":
        cmd_prepare(a); return 0
    if a.cmd == "record":
        cmd_record(a); return 0
    if a.cmd == "resolve":
        cmd_resolve(a); return 0
    if a.cmd == "check":
        bad = cmd_check(Path(a.root).resolve())
        if bad:
            print(f"FAIL: rulecheck check — {bad} finding(s)")
            return 1
        print("PASS: rulecheck check — the ledger, the fixtures, the calibrations and every freeze since the birth")
        return 0
    ap.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
