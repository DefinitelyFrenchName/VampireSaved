#!/usr/bin/env python3
"""command_throw_sheet.py — NINE TILES PER COMMAND-THROW RIG EVENT, ON PRISTINE VSAVJ (#329, 14z-211).

WHY IT EXISTS. tests/audit_command_throws.sh freezes each event as a line (held, kind, a signature hash) and its CAP
leg photographs one frame per event; the maintainer confirms what an input DOES on pictures, before any conclusion
(the rule-checker's Q2). #329's re-rigged motion test was put to the maintainer this way: these are the gate's own
rigs and pokes, re-run with nine snapshots per named event. An INSTRUMENT, not a gate: it asserts nothing.

THE RIG IS THE GATE'S: tests/replays/command_throws/<rig>.rpl with the pokes its .json lists, through
tools/run_replay_guarded.sh (GUARD_DEBUG=0, SNAP_FRAMES), as the gate's CAP leg. Each named event is drawn as one row:
the motion's first frame ("start"), the button's first frame ("press") and press +6 +12 +20 +30 +45 +60 +90; its header
gives the directions the game is FED on its frames (replay.lua's ranges are inclusive and its lines OR together:
docs/project/gotchas.md "A REPLAY RANGE IS INCLUSIVE") and the event's frozen `held` and `move_kind`. A leg that took
fewer snapshots than asked is VOID: the tool refuses to draw.

Usage:
  ROMDIR=... tools/command_throw_sheet.py <out.png> "<title>" "<SHEET>:<label>" ...
  e.g. tools/command_throw_sheet.py au.png "Aulbath" "AU:motion 6324HP minimal" "AU:motion 624HP"
Env: RIGS (default tests/replays/command_throws), EXPECTED (default tests/expected/command_throws.tsv), KEEP=<dir>
     (keep the runs there), SCALE (default 0.5). Needs PIL.
"""
import atexit
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OFFS = [("start", None), ("press", 0), ("+6", 6), ("+12", 12), ("+20", 20), ("+30", 30), ("+45", 45), ("+60", 60), ("+90", 90)]
NUM = {frozenset(): "5", frozenset("R"): "6", frozenset("L"): "4", frozenset("D"): "2", frozenset("U"): "8",
       frozenset("DR"): "3", frozenset("DL"): "1", frozenset("UR"): "9", frozenset("UL"): "7"}
LEGEND = ["TAGS: fed = the directions the game reads on the event's frames (a replay range holds every frame it names,",
          "both ends included, and lines OR together); HELD = P2 held by P1 (+0x134), the frozen row's `held`; KIND = the",
          "frozen `move_kind`: special / ES / EX = the move's own state, throw = the normal throw, '-' = neither.",
          "start = the motion's first frame; press = the button's first frame; +N = N frames after the press.",
          "P1 starts on the left (the rig's position pin), P2 on the right."]


def fed(rpl, a0, a1):
    """the directions P1's lines hold on each frame a0..a1, as numpad digits, and the run-length sequence"""
    held = {}
    for raw in open(rpl):
        m = re.match(r"^(\d+)(?:-(\d+))?\s+p1=(\S+)", raw.split("#")[0].strip())
        if not m:
            continue
        a, b = int(m.group(1)), int(m.group(2) or m.group(1))
        for fr in range(max(a, a0), min(b, a1) + 1):
            held.setdefault(fr, set()).update(c for c in m.group(3) if c in "UDLR")
    seq = [NUM.get(frozenset(held.get(fr, ())), "?") for fr in range(a0, a1 + 1)]
    return "".join(d for i, d in enumerate(seq) if d != "5" and (i == 0 or d != seq[i - 1]))


def main(argv):
    if len(argv) < 3 or not os.environ.get("ROMDIR"):
        sys.exit(__doc__.split("Usage:")[1].split("Env:")[0].rstrip() + "\n(ROMDIR must be set)")
    out, title, want = Path(argv[0]).resolve(), argv[1], argv[2:]
    rigs = REPO / os.environ.get("RIGS", "tests/replays/command_throws")
    exp = {}
    for l in open(REPO / os.environ.get("EXPECTED", "tests/expected/command_throws.tsv")):
        if l.strip() and not l.startswith("#"):
            f = l.rstrip("\n").split("\t")
            exp[(f[0], f[2])] = f
    events, legs = [], {}
    for w in want:
        sheet, label = w.split(":", 1)
        hit = [(j, e) for j in sorted(rigs.glob(f"ct_{sheet}_*.json")) for e in json.load(open(j))["events"] if e["label"] == label]
        if len(hit) != 1:
            sys.exit(f"REFUSED: {w!r} names {len(hit)} events in {rigs}")
        j, e = hit[0]
        frames = [e["frame"] if off is None else e["press"] + off for _, off in OFFS]
        events.append((sheet, label, j.stem, e, frames))
        legs.setdefault(j.stem, set()).update(frames)
    if os.environ.get("KEEP"):
        work = Path(os.environ["KEEP"]).resolve()
    else:   # the runs are scratch unless KEEP names a place for them (#303: every temporary removed at exit)
        work = Path(tempfile.mkdtemp(prefix="ctsheet."))
        atexit.register(shutil.rmtree, work, ignore_errors=True)
    work.mkdir(parents=True, exist_ok=True)

    def run(rig):
        o = work / rig
        o.mkdir(parents=True, exist_ok=True)
        pokes = ";".join(json.load(open(rigs / f"{rig}.json"))["pokes"])
        env = dict(os.environ, POKES=pokes, SNAP_FRAMES=",".join(str(f) for f in sorted(legs[rig])), GUARD_DEBUG="0")
        with open(o / "run.out", "w") as fo:
            subprocess.run([str(REPO / "tools/run_replay_guarded.sh"), "vsavj", str(rigs / f"{rig}.rpl"), str(o / "run.log"),
                            str(o / "sb")], cwd=o, env=env, stdout=fo, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL)
        shots = sorted((o / "sb/snap/vsavj").glob("*.png")) if (o / "sb/snap/vsavj").is_dir() else []
        return rig, shots
    with ThreadPoolExecutor(max_workers=min(4, len(legs))) as ex:
        shots = dict(ex.map(run, sorted(legs)))
    for rig, s in shots.items():
        if len(s) != len(legs[rig]):
            sys.exit(f"VOID: {rig} took {len(s)} snapshots, asked {len(legs[rig])} ({work / rig}/run.out)")
    at = {(rig, f): s for rig in shots for f, s in zip(sorted(legs[rig]), shots[rig])}

    from PIL import Image, ImageDraw, ImageFont
    font = big = ImageFont.load_default()
    for ttf in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        if os.path.exists(ttf):
            font, big = ImageFont.truetype(ttf, 15), ImageFont.truetype(ttf, 20)
            break
    w0, h0 = Image.open(at[(events[0][2], events[0][4][0])]).size
    sc = float(os.environ.get("SCALE", "0.5"))
    tw, th, head, cap, pad = int(w0 * sc), int(h0 * sc), 26, 18, 8
    page = Image.new("RGB", (9 * (tw + pad) + pad, 40 + 20 * len(LEGEND) + len(events) * (head + th + cap + pad) + pad), (16, 16, 16))
    d = ImageDraw.Draw(page)
    d.text((pad, 8), title, fill=(255, 255, 255), font=big)
    y = 40
    for t in LEGEND:
        d.text((pad, y), t, fill=(200, 200, 200), font=font)
        y += 20
    for sheet, label, rig, e, frames in events:
        r = exp.get((sheet, label))
        verdict = f"HELD {r[3]}, KIND {r[5]}" if r else "no frozen line"
        d.text((pad, y + 4), f"{label}   fed {fed(rigs / f'{rig}.rpl', e['frame'], e['press'] + 4)}   ->   {verdict}",
               fill=(240, 220, 120), font=font)
        y += head
        for k, f in enumerate(frames):
            x = pad + k * (tw + pad)
            page.paste(Image.open(at[(rig, f)]).convert("RGB").resize((tw, th)), (x, y))
            d.text((x + 2, y + th + 1), OFFS[k][0], fill=(200, 200, 200), font=font)
        y += th + cap + pad
    page.save(out)
    print(f"wrote {out} {page.size}; runs in {work}")


if __name__ == "__main__":
    main(sys.argv[1:])
