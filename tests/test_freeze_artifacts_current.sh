#!/bin/sh
# test_freeze_artifacts_current.sh — TRACKED ARTIFACTS THAT FOLLOW THE ROMSET
# MUST HAVE BEEN REFRESHED AT THE CURRENT FREEZE. (14z-144.)
#
# MUST-FIRE: perturbed-copy: one-value-change — build/merged1's ops with ONE value changed at an unchanged op count must fail section 1 (instance 3's shape; mode: that copy is compared)
# MUST-FIRE: known-bad: non-current-header — a prg_window header naming a non-current build dir must fail section 2 (mode: that header is what section 2 reads)
# MUST-FIRE: known-bad: stale-dir — a bundles-table row naming a superseded build dir as current must fail section 4 (mode: the row joins the real table)
# MUST-FIRE: known-bad: stale-fingerprint — a row naming a wrong fingerprint as CURRENT must fail section 4
# MUST-FIRE: known-bad: unregistered-but-registered — a row saying UNREGISTERED while naming a registered current build must fail section 4
# MUST-FIRE: known-bad: program-key-alias — a row naming the program-key alias of the huitzil freeze must fail section 4 (whole-set wins)
#
# WHY THIS EXISTS, and it is measured rather than argued. [VSP-178] says "a
# frozen expectation FOLLOWS whatever moves it, whatever the gate's cadence
# says". That rule was written at 14z-134 after test_mister_prg_window's pair
# shipped five freezes stale, and the remedy was to change that gate's CADENCE
# column to `romset`. A cadence column tells the RUNNER what to run. It says
# nothing to the FREEZE about what to REFRESH.
#
# So the class bit FOUR TIMES on 2026-09-09 alone:
#   1. M17 shipped with tests/expect/mister_prg_window.txt frozen on merged-m16
#   2. M17 shipped with build/merged1 two ops stale (829 vs 831)
#   3. build/merged1 went stale AGAIN within hours of being refreshed, by the
#      M18 fix — with an IDENTICAL op count, only a value differing, so any
#      count-based check would have missed it
#   4. the prg_window pair went stale again at the very next freeze — PREDICTED
#      IN ADVANCE that morning and still not prevented, because nothing asks
#
# THE DISCRIMINATOR — why only these two artifacts, and how to add a third.
# Every OTHER build-derived tracked artifact is already refreshed at every
# freeze, because a ci_static gate fails loudly when it is not: pointer_flow
# (test_pointer_flow), the charmap tables (test_charmap_current), the artifact
# manifests and reproducibility pins (test_m3a_reproducible), bases.tsv
# (audit_roster_pairings). None of those has ever rotted. The two that DID rot
# are exactly the two with no static-tier gate over their currency:
#   * tests/expect/mister_prg_window.txt — its gate is a ~1 h Verilator run, so
#     nothing in the static tier can see it go stale
#   * build/merged1/ — it REBUILDS itself, so its gate's verdict is about the
#     BUILD and staleness surfaces only as working-tree churn a human notices
# ADD A ROW when an artifact is (a) tracked, (b) derived from the build set, and
# (c) not already covered by a ci_static gate that fails on its staleness.
#
# THE THIRD ROW (14z-145): docs/project/patch_index.md's REGISTRATION CELLS —
# the "current generation … = `build/<dir>`" / "**CURRENT `<fp>`**" cells of the
# romset-bundles table. Measured before the row existed (2026-09-10, git log
# -S): those cells last moved at the 14z-119 freeze and named don_m18 / hui52 /
# pyron36 / m5_stock13 through 14z-130, 14z-132, 14z-143 AND 14z-144 — FOUR
# freezes stale — while the 14z-144 close edited OTHER cells of the same rows.
# Plus the two "UNREGISTERED … NOT yet frozen" instances the table records
# about itself (14z-127..132, 14z-143..144). Same discriminator: derived from
# the build set, read by no ci_static gate. Section 4 below.
#
# THE BUILD SET comes from tests/run_all_emulator.sh's placeholder defaults —
# the one machine-readable statement of "the current freeze" that is already
# re-pointed every freeze and already watched by test_build_ref_rot. Reading it
# here rather than re-declaring it means this gate cannot disagree with the
# runner about which build is current.
#
# Static, no emulator, ~1 s. Needs the current merged build dir.
# Usage: tests/test_freeze_artifacts_current.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; export REPO
cd "$REPO"

MERGED="$(sed -n 's/^MERGED="${MERGED:-\([^}]*\)}".*/\1/p' tests/run_all_emulator.sh | head -1)"
[ -n "$MERGED" ] || { echo "FAIL: could not read the MERGED default from tests/run_all_emulator.sh"; exit 1; }
# The four other tracks, same source (section 4 checks every track's cells).
DON="$(sed -n 's/^DON="${DON:-\([^}]*\)}".*/\1/p' tests/run_all_emulator.sh | head -1)"
HUI="$(sed -n 's/^HUI="${HUI:-\([^}]*\)}".*/\1/p' tests/run_all_emulator.sh | head -1)"
PYR="$(sed -n 's/^PYR="${PYR:-\([^}]*\)}".*/\1/p' tests/run_all_emulator.sh | head -1)"
STOCK="$(sed -n 's/^STOCK="${STOCK:-\([^}]*\)}".*/\1/p' tests/run_all_emulator.sh | head -1)"
for v in DON HUI PYR STOCK; do
    eval "x=\$$v"
    [ -n "$x" ] || { echo "FAIL: could not read the $v default from tests/run_all_emulator.sh"; exit 1; }
done
echo "== the current freeze, per tests/run_all_emulator.sh: $MERGED (don $DON, hui $HUI, pyr $PYR, stock $STOCK)"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
FAC_MODE="${VS_CTL:-}"; export FAC_MODE

MERGED="$MERGED" DON="$DON" HUI="$HUI" PYR="$PYR" STOCK="$STOCK" python3 - <<'PY'
import json, os, re, sys
from pathlib import Path
merged = os.environ["MERGED"]
MODE = os.environ.get("FAC_MODE", "")   # the CONTROL name: the known-bad input joins / replaces the real one
fails, notes = [], []
def fired(n, m): print(f"CONTROL FIRED: {n} — {m}")
def dead(n, m): print(f"CONTROL DEAD: {n} — {m}"); fails.append(f"CONTROL DID NOT FIRE — {n}")

def ops(p):
    o = json.loads(Path(p).read_text())
    return o["ops"] if isinstance(o, dict) and "ops" in o else o

def opkey(o):
    return (o.get("addr"), o.get("kind") or o.get("op"),
            json.dumps(o.get("hex") if "hex" in o else o.get("val"), sort_keys=True))

# ── 1. build/merged1 — the merged-legacy instrument ─────────────────────────
# It is the merged program image with gfx SKIPPED, generated from the SAME
# manifests in the same generator invocation, so its patch ops are EQUAL to the
# shipping merged build's. Measured 14z-144: identical as a set, 831 == 831.
# Comparing the ops CONTENT (not the count) is what catches instance 3, where
# the count was unchanged and one word differed.
src = Path("build/merged1/patch/patch.json")
dst = Path(merged) / "patch" / "patch.json"
if not src.exists():
    notes.append(f"1: SKIP — {src} absent")
elif not dst.exists():
    notes.append(f"1: SKIP — {dst} absent (no current merged build to compare against)")
else:
    a, b = ops(src), ops(dst)
    if MODE == "one-value-change":                 # the mode: instance 3's shape on the real comparison
        a = [dict(o) for o in a]
        for o in a:
            if "hex" in o and isinstance(o["hex"], str) and len(o["hex"]) > 4:
                o["hex"] = ("0" if o["hex"][0] != "0" else "1") + o["hex"][1:]; break
    ka, kb = set(map(opkey, a)), set(map(opkey, b))
    if ka != kb:
        fails.append(f"1: build/merged1 is STALE against {merged}: "
                     f"{len(a)} vs {len(b)} ops, {len(ka - kb)} only in merged1, "
                     f"{len(kb - ka)} only in the build — regenerate it "
                     f"(tests/audit_merged_legacy.sh rebuilds it) and COMMIT it")
    else:
        notes.append(f"1: build/merged1 matches {merged} — {len(a)} ops, "
                     f"identical as a set")

# ── 2. tests/expect/mister_prg_window.txt — the frozen pair ─────────────────
# Its header records which build each freeze measured it on. The NEWEST such
# record must name the current merged build dir.
exp = Path("tests/expect/mister_prg_window.txt")
if not exp.exists():
    fails.append(f"2: {exp} is missing")
else:
    hdr = [l for l in exp.read_text().splitlines() if l.startswith("#")]
    if MODE == "non-current-header":
        hdr = ["# frozen on merged-m0 (build/definitely_not_the_current_dir)"]
    dirs = re.findall(r"\(build/([A-Za-z0-9_]+)\)", "\n".join(hdr))
    want = merged.split("/", 1)[1]
    if not dirs:
        fails.append(f"2: {exp} header records no `(build/<dir>)` provenance — "
                     f"it cannot be checked for currency; state which build it "
                     f"was frozen on")
    elif want not in dirs:
        fails.append(f"2: {exp} is STALE: its header records {dirs}, none of "
                     f"which is the current {want}. Its pair follows the ROMSET "
                     f"([VSP-178]) — re-freeze it from a run's own measured "
                     f"line and re-run test_mister_prg_window under the runner")
    else:
        notes.append(f"2: {exp} records {want} — current")

# ── 3. MUST-FIRE CONTROLS ───────────────────────────────────────────────────
# Each perturbs the REAL comparison, not a copy of its own conclusion.
if src.exists() and dst.exists():
    a = ops(src)
    pert = [dict(o) for o in a]
    if pert:
        # instance-3 shape: same COUNT, one value changed
        for o in pert:
            if "hex" in o and isinstance(o["hex"], str) and len(o["hex"]) > 4:
                o["hex"] = ("0" if o["hex"][0] != "0" else "1") + o["hex"][1:]
                break
        if set(map(opkey, pert)) == set(map(opkey, ops(dst))):
            dead("one-value-change", "a one-value perturbation at an unchanged op count is invisible to the comparison")
        else:
            fired("one-value-change", "a one-VALUE change at an unchanged op count is caught (instance 3, the shape a count-based check would miss)")

hdr_txt = "# frozen on merged-m0 (build/definitely_not_the_current_dir)"
if re.findall(r"\(build/([A-Za-z0-9_]+)\)", hdr_txt)[0] == merged.split("/", 1)[1]:
    dead("non-current-header", "a wrong build dir in the header reads as current")
else:
    fired("non-current-header", "a header naming a non-current build dir is caught by section 2")

# ── 4. docs/project/patch_index.md — the REGISTRATION CELLS ─────────────────
# The romset-bundles table carries, per track, "current generation **<name>** =
# `build/<dir>`" / "current twin `build/<dir>`" and "**CURRENT `<fp>`** (<name>,
# …)". Those are CLAIMS about the current freeze and rot exactly like the two
# artifacts above (header: four freezes stale when this section was written).
#
# WHAT IS A CLAIM AND WHAT IS HISTORY — the 14z-144 re-point-sweep trap, [VSP-13]:
# only text after the word "current" is a claim, and of it only the FIRST build
# dir, the FIRST freeze name and the FIRST backticked fingerprint, up to the
# first ";", "prior" or cell boundary. Struck (~~…~~) and italic-parenthetical
# (*(…)*) spans are removed first: that is where the table quotes its own past
# wording. A "<name> (build/<dir>)" pairing in a prior clause is a dated fact
# and is never read. A cell saying UNREGISTERED / NOT yet frozen is checked the
# other way round: if it names a CURRENT build dir or fingerprint that the
# registry holds, it is stale.
#
# THE TRUTH is the runner's build set (dirs) + tools/build_fingerprint.py over
# each dir (program key and whole-set key) + tests/expected/registry.tsv (the
# names). Whole-set matches WIN: huitzil's program key 08944a7e has carried
# since huitzil-m26, so a cell saying "huitzil-m26" would pass a program-key
# lookup while the whole-set key says huitzil-m29 (control 4e).
import subprocess
tracks = {"DON": os.environ["DON"], "HUI": os.environ["HUI"], "PYR": os.environ["PYR"],
          "MERGED": merged, "STOCK": os.environ["STOCK"]}
FREEZE_RE = r"\b(?:donovan|huitzil|pyron|merged)-m\d+(?:-stock|-stage4)?\b"

def track_of_dir(d):
    for pre, t in (("m5_stock", "STOCK"), ("don_", "DON"), ("hui", "HUI"),
                   ("pyron", "PYR"), ("m3b_merged", "MERGED")):
        if d.startswith(pre):
            return t
    return None

def track_of_name(n):
    if n.endswith("-stock"):
        return "STOCK"
    if n.endswith("-stage4"):
        return "STAGE4"
    return {"donovan": "DON", "huitzil": "HUI", "pyron": "PYR", "merged": "MERGED"}[n.split("-")[0]]

def fingerprint(d, flag):
    rp = Path(d) / "rompath"
    setn = "vsavjw" if (rp / "vsavjw.zip").exists() else "vsavj"
    r = subprocess.run([sys.executable, "tools/build_fingerprint.py", str(rp),
                        "--set", setn, flag], capture_output=True, text=True)
    hits = [l.strip() for l in r.stdout.splitlines() if re.fullmatch(r"[0-9a-f]{40}", l.strip())]
    return hits[-1] if hits else None

registry = []
for l in Path("tests/expected/registry.tsv").read_text().splitlines():
    if l.startswith("#") or not l.strip():
        continue
    k, name = l.split("\t")[:2]
    registry.append((k.strip(), name.strip()))

truth = {}
for t, d in tracks.items():
    dname = d.split("/", 1)[1]
    if not (Path(d) / "rompath").is_dir():
        notes.append(f"4: {t} = {d} has no rompath on disk — its dir claims are "
                     f"checked, fingerprint/name claims UNVERIFIED")
        truth[t] = {"dir": dname, "prog": None, "set": None, "names": None}
        continue
    prog, sk = fingerprint(d, "--sha-only"), fingerprint(d, "--set-key")
    if not prog:
        fails.append(f"4: build_fingerprint.py returned no key for {d}")
        continue
    by_set = {n for k, n in registry if sk and k == sk}
    by_prog = {n for k, n in registry if k == prog}
    truth[t] = {"dir": dname, "prog": prog[:8], "set": sk[:8] if sk else None,
                "names": by_set or by_prog}
    if not truth[t]["names"]:
        fails.append(f"4: {d} ({prog[:8]} / {sk[:8] if sk else '-'}) is in NO registry "
                     f"row — the runner names an unregistered build as current")

def strip_history(s):
    s = re.sub(r"~~.*?~~", " ", s)
    s = re.sub(r"\*\(.*?\)\*", " ", s)
    return s

def claims(row):
    out = []
    s = strip_history(row)
    for m in re.finditer(r"\bcurrent\b", s, re.I):
        w = s[m.end(): m.end() + 300]
        cut = re.search(r";|\bprior\b|\|", w)
        if cut:
            w = w[:cut.start()]
        d = re.search(r"`build/([A-Za-z0-9_]+)`", w)
        n = re.search(FREEZE_RE, w)
        f = re.search(r"`([0-9a-f]{8})[0-9a-f]*`", w)
        if d or n or f:
            out.append((d and d.group(1), n and n.group(0), f and f.group(1),
                        re.sub(r"\s+", " ", (s[m.start(): m.end()] + w).strip())[:90]))
    return out

def check_rows(rows):
    fs, seen = [], 0
    for row in rows:
        for d, n, f, ctx in claims(row):
            t = (d and track_of_dir(d)) or (n and track_of_name(n))
            if t is None:
                fs.append(f"4: a CURRENT claim names an unrecognised build dir "
                          f"`build/{d}` — «{ctx}»")
                continue
            if t == "STAGE4" or t not in truth:
                continue
            tr = truth[t]
            seen += 1
            if n and track_of_name(n) != t:
                fs.append(f"4: CURRENT claim mixes the {t} dir with the freeze name "
                          f"{n} — «{ctx}»")
            if d and d != tr["dir"]:
                fs.append(f"4: STALE — names build/{d} as current for the {t} track; "
                          f"the current freeze is build/{tr['dir']} — «{ctx}»")
            if n and tr["names"] is not None and n not in tr["names"]:
                fs.append(f"4: STALE — names {n} as current for the {t} track; "
                          f"build/{tr['dir']} is registered as "
                          f"{'/'.join(sorted(tr['names']))} — «{ctx}»")
            if f and tr["prog"] is not None and f not in (tr["prog"], tr["set"]):
                fs.append(f"4: STALE — names fingerprint {f} as current for the {t} "
                          f"track; build/{tr['dir']} is {tr['prog']} (program) / "
                          f"{tr['set']} (whole-set) — «{ctx}»")
        s = strip_history(row)
        if re.search(r"\bUNREGISTERED\b|NOT yet frozen", s):
            named = set(re.findall(r"`build/([A-Za-z0-9_]+)`", s))
            fps = set(re.findall(r"`([0-9a-f]{8})[0-9a-f]*`", s))
            for t, tr in truth.items():
                if tr["names"] and (tr["dir"] in named or tr["prog"] in fps or tr["set"] in fps):
                    fs.append(f"4: STALE — a cell says UNREGISTERED / NOT yet frozen "
                              f"but names build/{tr['dir']}, registered as "
                              f"{'/'.join(sorted(tr['names']))}")
    return fs, seen

doc = Path("docs/project/patch_index.md")
lines = doc.read_text().splitlines()
rows, inside = [], False
for l in lines:
    if l.startswith("## "):
        inside = l.startswith("## Romset patch bundles")
        continue
    if inside and l.startswith("|") and not re.match(r"^\|\s*(Patch|-+)\s*\|", l):
        rows.append(l)
CTL_ROWS = {}
if truth.get("DON", {}).get("names"):
    CTL_ROWS["stale-dir"] = "| x | current generation **donovan-m3** = `build/don_m3` | - |"
    CTL_ROWS["stale-fingerprint"] = f"| x | **CURRENT `deadbeef`** (donovan-m22, `build/{truth['DON']['dir']}`) | - |"
    CTL_ROWS["unregistered-but-registered"] = f"| x | **UNREGISTERED** — `build/{truth['DON']['dir']}` expectation sets NOT yet frozen | - |"
if truth.get("HUI", {}).get("names") and "huitzil-m26" not in truth["HUI"]["names"]:
    CTL_ROWS["program-key-alias"] = f"| x | current generation **huitzil-m26** = `build/{truth['HUI']['dir']}` | - |"
if MODE in ("stale-dir", "stale-fingerprint", "unregistered-but-registered", "program-key-alias"):
    if MODE not in CTL_ROWS:
        print(f"REFUSED: CONTROL={MODE} is not a mode of this gate (its build is not on disk / registered)"); sys.exit(3)
    rows.append(CTL_ROWS[MODE])                  # the mode: the known-bad row joins the REAL table
if not rows:
    fails.append("4: the 'Romset patch bundles' table was not found in patch_index.md")
else:
    f4, seen = check_rows(rows)
    if seen == 0:
        fails.append("4: no CURRENT-marked claim found in the bundles table — the "
                     "table or this parser changed shape; nothing was checked")
    fails.extend(f4)
    if not f4 and seen:
        notes.append(f"4: patch_index.md bundles table — {seen} CURRENT claim(s) over "
                     f"{len(rows)} rows all name the current freeze")

# ── 4c. MUST-FIRE CONTROLS — synthetic rows against the REAL truth ──────────
def ctl(name, row, want_fail, must_contain=None):
    fs, _ = check_rows([row])
    hit = any((must_contain or "") in f for f in fs) if want_fail else not fs
    if want_fail:
        if hit: fired(name, f"the synthetic row is caught ({must_contain})")
        else: dead(name, f"the synthetic row passed — {fs[:2]}")
    elif hit:
        notes.append(f"4c: must-not-fire {name} stayed quiet")
    else:
        fails.append(f"4c: MUST-NOT-FIRE {name} DID NOT STAY QUIET — {fs[:2]}")

for name, row in CTL_ROWS.items():
    ctl(name, row, True, {"stale-dir": "names build/don_m3", "stale-fingerprint": "fingerprint deadbeef",
                          "unregistered-but-registered": "UNREGISTERED", "program-key-alias": "names huitzil-m26"}[name])
if truth.get("DON", {}).get("names"):
    ctl("history-is-not-a-target",
        "| x | ~~current generation **donovan-m3** = `build/don_m3`~~ *(this cell read "
        "\"current twin `build/don_m3`\")* — prior donovan-m3 `build/don_m3` | - |", False)

for n in notes:
    print("  " + n)
if fails:
    print()
    for f in fails:
        print("FAIL: " + f)
    print(f"\nFAIL: test_freeze_artifacts_current ({len(fails)} failure(s))")
    sys.exit(1)
print("\nPASS: every romset-following tracked artifact is current with "
      f"{merged}")
PY
