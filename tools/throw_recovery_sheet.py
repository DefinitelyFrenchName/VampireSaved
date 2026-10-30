#!/usr/bin/env python3
"""throw_recovery_sheet.py — THE CAPTURE SHEETS OF tests/audit_throw_recovery.sh (#330, 14z-211): nine tiles per event of
the gate's OWN rigs, so what the gate freezes as a tick is put before the maintainer as pictures (rule-checker run
2026-10-28-1361 Q2: a tech window and a "can act again" tick are conclusions a player feels).

THE RIGS ARE THE GATE'S: tools/throw_recovery_rigs.py gen from the frozen full lines outside the tree (TR_FULL), each
rig run once under tools/run_replay_guarded.sh without the debugger (GUARD_DEBUG=0) with SNAP_FRAMES at its rows'
frames. Every tile is labelled with its offset in ENGINE TICKS from the event's press (the throw's commit; a command
throw's press), at speed level 0 a tick a frame.

THE PAGES (rows_for below): air-throw — the air throw itself from the jump, the #229 level-6 rig against the gate's
level-0 one; air-lp — the air and command LP pairs, larger; tech — a throw untouched against the same throw teched at k = 1, and the window's edge (k = 7
teched, k = 8 not); ground / air-lp / command-lp (a grab's whiff) — a one-frame LP pressed one tick BEFORE the frozen tick (it must never come out)
against one pressed ON it (it must); giga — Victor's Giga Shock untouched against the victim's press 1 tick into the hold
(the command family's ticks, outside the tree and not yet frozen in it).

Usage: ROMDIR=... python3 tools/throw_recovery_sheet.py <out dir> [page ...]      (KEEP=<dir> keeps the runs)
       SHEET_CTL=wrong-presser ... — the caption check's control: it reads the other fighter and the sheet must REFUSE"""
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
sys.path.insert(0, str(REPO / "tools"))
import throw_recovery_rigs as trr  # noqa: E402


def lp_offs(a):
    return [a - 2, a - 1, a, a + 1, a + 2, a + 4, a + 6, a + 9, a + 14]


def ticks(family, rig):
    os.environ["TR_FAMILY"] = family
    p = trr.full_path()
    if family == "command":
        return trr.cmd_read_ticks(p)[rig]
    return trr.read_ticks(p)[rig]


def rows_for(page):
    """[(family, rig, case, label suffix, row title, offsets)]"""
    if page == "tech":
        fe = [0, 8, 20, 35, 47, 54, 70, 100, 150]
        au = [0, 10, 20, 30, 40, 55, 75, 95, 115]
        return [("ground", "FE_0", "thrown", "thrown control", "Felicia 6MP on Victor — THROWN (no tech)", fe),
                ("ground", "FE_0", "teched", "teched control", "Felicia 6MP on Victor — TECHED (victim back+MP at k=1)", fe),
                ("ground", "FE_0", "teched", "teched tech@7", "Felicia 6MP — tech at k=7 (the window's last tick)", fe),
                ("ground", "FE_0", "thrown", "thrown tech@8", "Felicia 6MP — tech at k=8 (past the window: thrown)", fe),
                ("ground", "AU_0", "thrown", "thrown control", "Aulbath 6MP on Victor — THROWN", au),
                ("ground", "AU_0", "teched", "teched control", "Aulbath 6MP on Victor — TECHED at k=1", au)]
    if page == "ground":
        out = []
        for rig, case, who, col, name in (("FE_0", "thrown", "p1", "thr_thrown", "Felicia (thrower), 6MP thrown"),
                                          ("FE_0", "thrown", "p2", "vic_thrown", "Victor (victim), Felicia 6MP thrown"),
                                          ("QB_0", "thrown", "p1", "thr_thrown", "Q-Bee (thrower), 6MP thrown — a landing"),
                                          ("VI_2", "teched", "p1", "thr_tech", "Victor (thrower), 6MK teched — a held neutral")):
            a = ticks("ground", rig)[col]
            for o, tag in ((a - 1, "one tick BEFORE"), (a, "ON the tick")):
                out.append(("ground", rig, case, f"{who} LP@+{o} A={a}", f"{name}: LP {tag} (A={a})", lp_offs(a)))
        return out
    if page == "air-throw":
        # the air throw itself, from the jump: the frozen level-6 rig #229 confirmed (family "orig":
        # tests/replays/ground_throws/gt_<TAB>_air, its j.6MP event) against the gate's level-0 rig, offsets from the press
        out = []
        for tab, name in (("FE", "Felicia"), ("GA", "Gallon"), ("LI", "Lilith")):
            at = trr.AIR_AT.get(tab, 17)
            out.append(("orig", f"gt_{tab}_air", "-", "j.6MP", f"{name} j.6MP — the #229 rig at speed level 6 (frames from its press)",
                        [-14, -10, -6, -3, 0, 3, 8, 16, 30]))
            out.append(("air", f"{tab}_air_0", "thrown", "thrown control", f"{name} j.6MP — the gate's level-0 rig (ticks from its press)",
                        [-at, -12, -7, -4, 0, 4, 10, 20, 36]))
        return out
    if page == "air-lp":
        out = []
        a = ticks("air", "FE_air_0")["thr_thrown"]
        for o, tag in ((a - 1, "one tick BEFORE"), (a, "ON the tick")):
            out.append(("air", "FE_air_0", "thrown", f"p1 LP@+{o} A={a}", f"Felicia (thrower), j.6MP thrown: LP {tag} (A={a})",
                        [a - 1, a, a + 1, a + 2, a + 3, a + 4, a + 5, a + 7, a + 10]))
        # (the command whiffs are not on this page: build/agent212/t330's capture pages showed the 8 that are not plain)
        return out
    if page == "command-lp":
        # a command grab's WHIFF: a one-frame LP one tick before the frozen tick against one on it (14z-212, #330) — a
        # constant-offset row (Sasquatch) and an ES grab's own whiff (Aulbath, seq 0x12: "Yes, it is the whiff")
        out = []
        for rig, name in (("SA_cmd_1", "Sasquatch 632[4] MP, whiffed"), ("AU_cmd_3", "Aulbath ES 6324PP, whiffed")):
            a = ticks("command", rig)[1]
            for o, tag in ((a - 1, "one tick BEFORE"), (a, "ON the tick")):
                out.append(("command", rig, "whiff", f"whiff p1 LP@+{o} A={a}", f"{name}: LP {tag} (A={a})", lp_offs(a)))
        return out
    if page == "giga":
        h = ticks("command", "VI_cmd_0")[0]
        offs = [0, h + 5, h + 20, h + 35, h + 41, h + 50, h + 70, h + 100, h + 200]
        return [("command", "VI_cmd_0", "teched", "teched control", "Victor Giga Shock 236LK on Demitri — untouched", offs),
                ("command", "VI_cmd_0", "teched", "teched tech" + trr.nm.B["HP"] + "@1", "Victor Giga Shock 236LK — Demitri back+HP 1 tick into the hold", offs)]
    sys.exit(f"no such page: {page}")


def main(argv):
    if not argv or not os.environ.get("ROMDIR"):
        sys.exit(__doc__.split("Usage:")[1].rstrip() + "\n(ROMDIR must be set)")
    out = Path(argv[0]).resolve(); out.mkdir(parents=True, exist_ok=True)
    pages = argv[1:] or ["tech", "ground", "air-throw", "air-lp", "command-lp", "giga"]
    if os.environ.get("KEEP"):
        work = Path(os.environ["KEEP"]).resolve()
    else:   # the runs are scratch unless KEEP names a place for them (#303: every temporary removed at exit)
        work = Path(tempfile.mkdtemp(prefix="trsheet."))
        atexit.register(shutil.rmtree, work, ignore_errors=True)
    work.mkdir(parents=True, exist_ok=True)
    plan = {p: rows_for(p) for p in pages}
    rigs = {}   # (family, rig, case) -> {the frames}
    for rows in plan.values():
        for fam, rig, case, *_ in rows:
            rigs.setdefault((fam, rig, case), set())
    # the rigs, made by the gate's generator from the frozen ticks
    for fam in sorted({k[0] for k in rigs} - {"orig"}):
        env = dict(os.environ, TR_FAMILY=fam)
        only = ",".join(sorted({k[1] for k in rigs if k[0] == fam}))
        subprocess.run([sys.executable, str(REPO / "tools/throw_recovery_rigs.py"), "gen", trr_full(fam), str(work / fam), "--only", only],
                       env=env, check=True, stdout=subprocess.DEVNULL)
    sched, frames = {}, {}
    for rows in plan.values():
        for fam, rig, case, suf, title, offs in rows:
            j = json.load(open(rig_path(work, fam, rig, case) + ".json"))
            hit = [e for e in j["events"] if e["input"].endswith(" " + suf) or (fam == "orig" and e["input"] == suf)]
            if len(hit) != 1:
                sys.exit(f"REFUSED: {fam} {rig} {case} {suf!r} names {len(hit)} events")
            sched[(fam, rig, case, suf)] = hit[0]
            rigs[(fam, rig, case)].update(hit[0]["press"] + o for o in offs)

    def run(k):
        fam, rig, case = k
        o = work / f"run_{fam}_{rig}_{case}"; o.mkdir(parents=True, exist_ok=True)
        j = json.load(open(rig_path(work, fam, rig, case) + ".json"))
        # each snapshot frame also DUMPS both fighters' +0x04 (the state long) — the caption prints it, so a tile's frame is
        # shown by the game's own state, not assumed (the maintainer, 2026-10-28: "the time captured ... does not align?")
        dumps = ";".join(f"{f}:ff8404-ff8407;{f}:ff8804-ff8807" for f in sorted(rigs[k]))
        env = dict(os.environ, POKES=";".join(j["pokes"]), SNAP_FRAMES=",".join(str(f) for f in sorted(rigs[k])), GUARD_DEBUG="0",
                   DUMPS=dumps)
        with open(o / "run.out", "w") as fo:
            subprocess.run([str(REPO / "tools/run_replay_guarded.sh"), "vsavj", rig_path(work, fam, rig, case) + ".rpl", str(o / "run.log"),
                            str(o / "sb")], cwd=o, env=env, stdout=fo, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL)
        shots = sorted((o / "sb/snap/vsavj").glob("*.png")) if (o / "sb/snap/vsavj").is_dir() else []
        for f in sorted(rigs[k]):
            for who, a in (("p1", "ff8404"), ("p2", "ff8804")):
                dp = o / f"dump_{f}_{a}.bin"
                state[(k, f, who)] = int.from_bytes(dp.read_bytes(), "big") if dp.exists() and dp.stat().st_size == 4 else None
        return k, shots
    state = {}
    with ThreadPoolExecutor(max_workers=min(8, len(rigs))) as ex:
        shots = dict(ex.map(run, sorted(rigs)))
    for k, s in shots.items():
        if len(s) != len(rigs[k]):
            sys.exit(f"VOID: {k} took {len(s)} snapshots, asked {len(rigs[k])}")
    at = {(k, f): s for k in shots for f, s in zip(sorted(rigs[k]), shots[k])}

    # THE CAPTION'S CONTROL (rule-checker run 2026-10-28-1362 Q4: a caption printed the thrower's state under the victim's
    # presses): on every LP row the PRESSER's dumped state must start the normal (seq 0x0A) at A on the ON row and on no
    # tile of the BEFORE row, or the sheet refuses
    bad = []
    for rows in plan.values():
        for fam, rig, case, suf, title, offs in rows:
            m = re.search(r"(p1|p2) LP@\+(\d+) A=(\d+)$", suf)
            if not m:
                continue
            who, o, a = m.group(1), int(m.group(2)), int(m.group(3)); e = sched[(fam, rig, case, suf)]
            if os.environ.get("SHEET_CTL") == "wrong-presser":   # the control: read the OTHER fighter, the 1362 defect
                who = "p1" if who == "p2" else "p2"
            normal = [x for x in offs if (state.get(((fam, rig, case), e["press"] + x, who)) or 0) & 0x00ffff00 == 0x00000a00]
            if o == a and a not in normal:
                bad.append(f"{title}: the presser ({who}) is not in the normal at A")
            if o == a - 1 and normal:
                bad.append(f"{title}: the presser ({who}) is in the normal at {normal}")
    if bad:
        sys.exit("REFUSED (the caption's control):\n  " + "\n  ".join(bad))
    from PIL import Image, ImageDraw, ImageFont
    font = big = ImageFont.load_default()
    for ttf in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        if os.path.exists(ttf):
            font, big = ImageFont.truetype(ttf, 15), ImageFont.truetype(ttf, 20)
            break
    legend = ["UNDER EACH TILE: its offset, then the presser's state long +0x04 DUMPED AT THAT FRAME by the same run; LP (red) = the",
              "light punch's state (seq 0x0A) — so a tile's frame is read from the game, not assumed.",
              "TAGS: +N = engine ticks after the press (the throw's commit; a command throw's button press); speed level 0,",
              "one tick a frame; victim Victor (Demitri when Victor throws). 'LP one tick BEFORE / ON the tick' = a one-frame",
              "light punch pressed at A-1 or at A, A the frozen tick the gate re-proves: it must come out only ON the tick."]
    for page, rows in plan.items():
        first = at[((rows[0][0], rows[0][1], rows[0][2]), sched[tuple(rows[0][:4])]["press"] + rows[0][5][0])]
        w0, h0 = Image.open(first).size
        sc = float(os.environ.get("SCALE", "1.0" if page in ("air-lp", "ground") else "0.5"))
        tw, th, head, cap, pad = int(w0 * sc), int(h0 * sc), 26, 18, 8
        img = Image.new("RGB", (9 * (tw + pad) + pad, 40 + 20 * len(legend) + len(rows) * (head + th + cap + pad) + pad), (16, 16, 16))
        d = ImageDraw.Draw(img)
        d.text((pad, 8), f"#330 throw recovery — {page}", fill=(255, 255, 255), font=big)
        y = 40
        for t in legend:
            d.text((pad, y), t, fill=(200, 200, 200), font=font); y += 20
        for fam, rig, case, suf, title, offs in rows:
            e = sched[(fam, rig, case, suf)]
            who = "p2" if re.match(r"(?:\w+ )?p2 LP@", suf) else "p1"   # the PRESSER: "p2 LP@…" / "whiff p1 LP@…"
            d.text((pad, y + 4), title, fill=(240, 220, 120), font=font); y += head
            for i, o in enumerate(offs):
                x = pad + i * (tw + pad)
                img.paste(Image.open(at[((fam, rig, case), e["press"] + o)]).convert("RGB").resize((tw, th)), (x, y))
                v = state.get(((fam, rig, case), e["press"] + o, who))
                tag = "" if v is None else f" {who.upper()} {v:08x}" + ("  LP" if (v & 0x00ffff00) == 0x00000a00 else "")
                d.text((x + 2, y + th + 1), f"{o:+d}{tag}", fill=(255, 120, 120) if tag.endswith("LP") else (200, 200, 200), font=font)
            y += th + cap + pad
        p = out / f"throw_recovery_{page}.png"; img.save(p)
        print(f"wrote {p} {img.size}")
    print(f"runs in {work}")


def rig_path(work, fam, rig, case):
    """the rig's path without its extension: the gate's (made in <work>/<family>) or, family orig, the committed #229 rig"""
    if fam == "orig":
        return str(REPO / "tests/replays/ground_throws" / rig)
    return str(work / fam / f"tr_{rig}_{case}")


def trr_full(fam):
    os.environ["TR_FAMILY"] = fam
    return trr.full_path()


if __name__ == "__main__":
    main(sys.argv[1:])
