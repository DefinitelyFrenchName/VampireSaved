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
     14z-193/194); SIGINT to pw-record (finalises the WAV header), KILL after 10 s — ALWAYS, even when
     a step raised (#310 group 7, 14z-223: a dead xwd made `cap` raise, the stop was skipped, and the
     emulators and recorders of two runs kept playing into the sink, failing the next run's signal and
     link checks on PILOT);
  5. writes <out>/drive.jsonl, one JSON object per event with its epoch time `t`, including
     `rec_start` (when pw-record was started) and the emulator's end.
The whole run is bounded by --bound seconds (default 150). Exit 0 when the run completed its
steps; 3 when pw-record died, the session is unreachable, another live harness owns the session
(`owned`: /run/user/<uid>/vampire-saved-desktop.owner names a live pid other than $VS_DESKTOP_OWNER;
tests/lib/desktop_session.sh), another emulator's audio stream is already on the session (`stray`:
every judgement here assumes the session plays this run alone), or no emulator window ever appeared. `apprec` records only a stream of THIS run's emulator (its process in
the launched process group), never another process of the same binary name.
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
    # the CLIENT window, never its frame: GNOME 46 draws decorations in a separate X client whose frame window carries
    # the client's title and is listed first; since mutter 46.2-1ubuntu0.24.04.18 an XSetInputFocus on that frame takes
    # focus FROM the game (FBNeo pauses on focus loss), measured on PILOT 14z-216 (docs/platform/gotchas.md)
    for l in t.splitlines():
        if ("Vampire" in l or "FinalBurn" in l or "MAME" in l or "vsav" in l) and "has no name" not in l \
                and "mutter-x11-frames" not in l:
            return l.split()[0]
    return None

props = "{ stream.capture.sink=true %s}" % "".join(p + " " for p in a.rec_prop)
def stream_nodes(dump):
    """(node id, props, owning pid or None) of every audio output stream node in a pw-dump; the pid is the node's
    application.process.id or, failing that, its client's"""
    clients = {o["id"]: ((o.get("info") or {}).get("props") or {}) for o in dump if o.get("type") == "PipeWire:Interface:Client"}
    out = []
    for o in dump:
        pr = (o.get("info") or {}).get("props") or {}
        if o.get("type") != "PipeWire:Interface:Node" or not pr.get("media.class", "").startswith("Stream/Output/Audio"):
            continue
        pid = pr.get("application.process.id") or clients.get(pr.get("client.id"), {}).get("application.process.id")
        out.append((o["id"], pr, int(pid) if str(pid or "").isdigit() else None))
    return out

def pwdump():
    return json.loads(subprocess.run(["pw-dump"], capture_output=True, text=True, env=env, timeout=20).stdout or "[]")

# one harness at a time on the session (tests/lib/desktop_session.sh, #310 group 7, 14z-223): a live owner that is not
# the harness this run belongs to (VS_DESKTOP_OWNER, inherited) owns the sink, the graph and the keyboard focus
_own = f"/run/user/{uid}/vampire-saved-desktop.owner"
try:
    _ow = open(_own).read().split(None, 1)
except OSError:
    _ow = []
if _ow and _ow[0].isdigit() and _ow[0] != os.environ.get("VS_DESKTOP_OWNER", ""):
    try:
        os.kill(int(_ow[0]), 0); _alive = True
    except ProcessLookupError:
        _alive = False
    except PermissionError:
        _alive = True
    if _alive:
        ev("owned", owner=" ".join(_ow).strip()); print("another harness owns the desktop session: %s" % " ".join(_ow).strip()); sys.exit(3)
# another emulator already playing on the session (a leftover of an earlier run) would be read as this run's sound
# and links: refuse before starting anything (#310 group 7, 14z-223)
stray = [(i, pr.get("application.process.binary"), pid) for i, pr, pid in stream_nodes(pwdump())
         if pr.get("application.process.binary") in ("fbneo", "cps2", "mame")]
if stray:
    ev("stray", streams=stray); print("another emulator's audio stream is already on the session: %s" % stray); sys.exit(3)
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
def own(pid):
    try: return pid is not None and os.getpgid(pid) == p.pid
    except OSError: return False
try:
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
          # only THIS run's emulator: a node of the binary whose process is in the launched process group
          named = [(i, pid) for i, pr, pid in stream_nodes(pwdump()) if pr.get("application.process.binary") == binary]
          ids = [i for i, pid in named if own(pid)]
          if not ids:
              ev("apprec", binary=binary, found=False, others=len(named)); continue
          r2 = subprocess.Popen(["pw-record", "--target", str(ids[0]), "--rate", "48000", "--channels", "2",
                                 "--format", "s16", os.path.join(a.out, "app.wav")], env=env,
                                stdin=subprocess.DEVNULL, stdout=open(os.path.join(a.out, "app-record.log"), "w"),
                                stderr=subprocess.STDOUT)
          time.sleep(float(secs or 15))
          r2.send_signal(signal.SIGINT)
          try: r2.wait(10)
          except subprocess.TimeoutExpired:
              r2.kill(); r2.wait()
          ev("apprec", binary=binary, found=True, node=ids[0], others=len(named) - len(ids), seconds=float(secs or 15), code=r2.returncode); continue
      wid = window() or wid
      if not wid:
          ev("no_window", step=step); continue
      seen_window = True
      if kind == "cap":
          f = os.path.join(a.out, "%s.xwd" % arg)
          r = subprocess.run(["xwd", "-id", wid, "-out", f], capture_output=True, text=True, env=env, timeout=20)
          # no .xwd (xwd failed or is absent): logged as png=False, never a crash (#310 group 7, 14z-223)
          if os.path.exists(f):
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

finally:
  # stop the emulator's whole process group, then the recorder — also when a step raised (the traceback still
  # surfaces and the exit is non-zero; #310 group 7, 14z-223)
  # the GROUP, whether or not its leader (sh PLAY.command) is still alive: an emulator outliving the leader is still in
  # it; whatever of the group is left after the leader's 10 s gets KILL
  try: os.killpg(p.pid, signal.SIGTERM)
  except ProcessLookupError: pass
  try: p.wait(10)
  except subprocess.TimeoutExpired: pass
  time.sleep(0.5)
  try: os.killpg(p.pid, signal.SIGKILL)
  except ProcessLookupError: pass
  p.wait()
  ev("emu_end", code=p.returncode)
  rec.send_signal(signal.SIGINT)
  try: rec.wait(10)
  except subprocess.TimeoutExpired:
      rec.kill(); rec.wait()
  ev("rec_end", code=rec.returncode)
sys.exit(0 if seen_window else 3)
