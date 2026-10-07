#!/usr/bin/env python3
"""desktop_session_play.py — play a RELEASE package the player's way inside a live Linux desktop
session, recording its sound, and log every step with its time (#226, 14z-194).

  desktop_session_play.py --pd <platform dir> --out <dir> --steps <steps>
                          [--target <sink>] [--rec-prop K=V]... [--arg <emulator arg>]...
                          [--env K=V]... [--bound S]

Generalised from the 14z-193 hand driver (build/agent193/t226/pilot_drive.py). What it does:
  1. starts `pw-record -P '{ stream.capture.sink=true }' --target <sink>` (default the null sink
     `auto_null`) into <out>/rec.wav, and checks it is alive after 1 s;
  2. launches `sh PLAY.command <args>` from <pd> in its OWN process group, with DISPLAY=:0 and the
     session's Xwayland auth file (an X11 client under Xwayland), environment plus --env;
  3. plays <steps>, comma-separated: `wait:<s>`, `cap:<label>` (the emulator window via `xwd -id`,
     converted to <label>.png), `key:<keysym>[:<hold s>]` (one key through XTEST to the focused
     emulator window — the release binaries carry no harness), `pwdump:<label>` (a `pw-dump`
     snapshot to pwdump_<label>.json), `apprec:<binary>:<s>` (record the emulator's OWN output
     stream — the node whose application.process.binary is <binary> — for <s> seconds into
     app.wav; the sink monitor also carries the desktop's own event sounds);
  4. stops: TERM to the emulator's process group, KILL after 10 s (MAME ignores TERM, paid
     14z-193/194); SIGINT to pw-record (finalises the WAV header), KILL after 10 s;
  5. writes <out>/drive.jsonl, one JSON object per event with its epoch time `t`, including
     `rec_start` (when pw-record was started) and the emulator's end.
The whole run is bounded by --bound seconds (default 150). Exit 0 when the run completed its
steps; 3 when pw-record died, the session is unreachable or no emulator window ever appeared.
"""
import argparse, ctypes, glob, json, os, signal, subprocess, sys, time

ap = argparse.ArgumentParser()
ap.add_argument("--pd", required=True); ap.add_argument("--out", required=True)
ap.add_argument("--steps", required=True); ap.add_argument("--target", default="auto_null")
ap.add_argument("--arg", action="append", default=[]); ap.add_argument("--env", action="append", default=[])
ap.add_argument("--bound", type=float, default=150.0)
ap.add_argument("--rec-prop", action="append", default=[],
                help="an extra pw-record stream property K=V (e.g. node.autoconnect=false: the recorder links to nothing)")
a = ap.parse_args()
os.makedirs(a.out, exist_ok=True)

uid = os.getuid()
auth = sorted(glob.glob(f"/run/user/{uid}/.mutter-Xwaylandauth.*"))
if not auth:
    print(f"no live session: no /run/user/{uid}/.mutter-Xwaylandauth.*"); sys.exit(3)
env = dict(os.environ, DISPLAY=":0", XDG_RUNTIME_DIR=f"/run/user/{uid}", XAUTHORITY=auth[0])
for kv in a.env:
    k, _, v = kv.partition("="); env[k] = v
os.environ.update(DISPLAY=env["DISPLAY"], XAUTHORITY=env["XAUTHORITY"], XDG_RUNTIME_DIR=env["XDG_RUNTIME_DIR"])

x11 = ctypes.CDLL("libX11.so.6"); xt = ctypes.CDLL("libXtst.so.6")
x11.XOpenDisplay.restype = ctypes.c_void_p
x11.XStringToKeysym.restype = ctypes.c_ulong
x11.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
xt.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
x11.XSetInputFocus.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int, ctypes.c_ulong]
x11.XRaiseWindow.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
x11.XFlush.argtypes = [ctypes.c_void_p]; x11.XSync.argtypes = [ctypes.c_void_p, ctypes.c_int]
dpy = x11.XOpenDisplay(None)
if not dpy:
    print("no X display at :0"); sys.exit(3)

log = open(os.path.join(a.out, "drive.jsonl"), "w")
T0 = time.time()
def ev(kind, **kw):
    kw.update(ev=kind, t=round(time.time(), 3)); log.write(json.dumps(kw) + "\n"); log.flush()
    print("%7.1f %s %s" % (time.time() - T0, kind, " ".join("%s=%s" % i for i in kw.items() if i[0] not in ("ev", "t"))), flush=True)

def window():
    t = subprocess.run(["xwininfo", "-root", "-tree"], capture_output=True, text=True, env=env).stdout
    for l in t.splitlines():
        if ("Vampire" in l or "FinalBurn" in l or "MAME" in l or "vsav" in l) and "has no name" not in l:
            return l.split()[0]
    return None

props = "{ stream.capture.sink=true %s}" % "".join(p + " " for p in a.rec_prop)
rec = subprocess.Popen(["pw-record", "-P", props, "--target", a.target,
                        "--rate", "48000", "--channels", "2", "--format", "s16",
                        os.path.join(a.out, "rec.wav")], env=env, stdin=subprocess.DEVNULL,
                       stdout=open(os.path.join(a.out, "pw-record.log"), "w"), stderr=subprocess.STDOUT)
ev("rec_start", pid=rec.pid, target=a.target, props=props)
time.sleep(1)
if rec.poll() is not None:
    ev("rec_died", code=rec.returncode); sys.exit(3)

p = subprocess.Popen(["sh", "PLAY.command"] + a.arg, cwd=a.pd, env=env, stdin=subprocess.DEVNULL,
                     stdout=open(os.path.join(a.out, "emu.log"), "w"), stderr=subprocess.STDOUT,
                     start_new_session=True)
ev("launch", pid=p.pid, args=a.arg, env=a.env)
wid = None; seen_window = False; rc = 0
for step in a.steps.split(","):
    if time.time() - T0 > a.bound:
        ev("stop", why="bound %.0f s" % a.bound); break
    if p.poll() is not None:
        ev("stop", why="emulator exited %s" % p.returncode); break
    kind, _, arg = step.partition(":")
    if kind == "wait":
        time.sleep(float(arg)); continue
    if kind == "pwdump":
        f = os.path.join(a.out, "pwdump_%s.json" % arg)
        with open(f, "w") as fh:
            subprocess.run(["pw-dump"], stdout=fh, stderr=subprocess.DEVNULL, env=env, timeout=20)
        ev("pwdump", label=arg, bytes=os.path.getsize(f)); continue
    if kind == "apprec":
        # record the EMULATOR'S OWN output stream for <s> seconds into app.wav (blocking):
        # the sink monitor also carries the desktop's event sounds (gnome-shell, measured
        # 14z-194), so signal is judged on the stream the emulator itself plays
        binary, _, secs = arg.partition(":")
        dump = json.loads(subprocess.run(["pw-dump"], capture_output=True, text=True, env=env, timeout=20).stdout or "[]")
        ids = [o["id"] for o in dump if o.get("type") == "PipeWire:Interface:Node"
               and ((o.get("info") or {}).get("props") or {}).get("application.process.binary") == binary
               and ((o.get("info") or {}).get("props") or {}).get("media.class", "").startswith("Stream/Output/Audio")]
        if not ids:
            ev("apprec", binary=binary, found=False); continue
        r2 = subprocess.Popen(["pw-record", "--target", str(ids[0]), "--rate", "48000", "--channels", "2",
                               "--format", "s16", os.path.join(a.out, "app.wav")], env=env,
                              stdin=subprocess.DEVNULL, stdout=open(os.path.join(a.out, "app-record.log"), "w"),
                              stderr=subprocess.STDOUT)
        time.sleep(float(secs or 15))
        r2.send_signal(signal.SIGINT)
        try: r2.wait(10)
        except subprocess.TimeoutExpired:
            r2.kill(); r2.wait()
        ev("apprec", binary=binary, found=True, node=ids[0], seconds=float(secs or 15), code=r2.returncode); continue
    wid = window() or wid
    if not wid:
        ev("no_window", step=step); continue
    seen_window = True
    if kind == "cap":
        f = os.path.join(a.out, "%s.xwd" % arg)
        r = subprocess.run(["xwd", "-id", wid, "-out", f], capture_output=True, text=True, env=env, timeout=20)
        subprocess.run(["convert", f, f[:-4] + ".png"], env=env, timeout=60)
        os.remove(f)
        ev("cap", label=arg, window=wid, png=os.path.exists(f[:-4] + ".png"), err=r.stderr.strip())
    elif kind == "key":
        name, _, hold = arg.partition(":")
        x11.XRaiseWindow(dpy, int(wid, 16)); x11.XSetInputFocus(dpy, int(wid, 16), 2, 0); x11.XSync(dpy, 0)
        kc = x11.XKeysymToKeycode(dpy, x11.XStringToKeysym(name.encode()))
        xt.XTestFakeKeyEvent(dpy, kc, 1, 0); x11.XFlush(dpy); time.sleep(float(hold or 0.15))
        xt.XTestFakeKeyEvent(dpy, kc, 0, 0); x11.XFlush(dpy)
        ev("key", key=name, keycode=kc, window=wid)

# stop the emulator's whole process group, then the recorder
if p.poll() is None:
    try: os.killpg(p.pid, signal.SIGTERM)
    except ProcessLookupError: pass
    try: p.wait(10)
    except subprocess.TimeoutExpired:
        os.killpg(p.pid, signal.SIGKILL); p.wait()
ev("emu_end", code=p.returncode)
rec.send_signal(signal.SIGINT)
try: rec.wait(10)
except subprocess.TimeoutExpired:
    rec.kill(); rec.wait()
ev("rec_end", code=rec.returncode)
sys.exit(0 if seen_window else 3)
