#!/usr/bin/env python3
"""patch_site_read.py — WHICH FIX DOES EACH BUILD CARRY, read from the build's OWN program image.
(14z-185, the M21 freeze: two builds that read byte-identical on every instrument cannot be told apart by
those instruments — rule-checker run 2026-09-28-403; promoted from build/rc185/sites/site_check.sh by the
close checklist's step 5.)

Usage:
  ROMDIR=... python3 tools/patch_site_read.py --build build/m3b_merged28 --build build/m3b_merged31 \\
         --site 0x01886C:#159 --site 0x02393A:#182 [--set vsavjw] [--pristine vsavj]

For each build: its program key and whole-set key (tools/build_fingerprint.py, --sha-only and --set-key run
SEPARATELY — --sha-only wins when both are given), then its decrypted OPCODE view (tools/cps2_decrypt.py on
<build>/rompath/<set>.zip), and at each site whether it is `jmp abs.l` (opcode word 0x4EF9, the site_thunk
form) and to where, or EQUAL to the pristine set's opcode view at the same six bytes (decrypted from
$ROMDIR/<pristine>.zip), or NEITHER. No ROM byte is printed. Exit 1 when a site reads NEITHER.
"""
import argparse, os, subprocess, sys, tempfile
ap = argparse.ArgumentParser()
ap.add_argument("--build", action="append", required=True)
ap.add_argument("--site", action="append", required=True, help="ADDR:LABEL, ADDR in hex")
ap.add_argument("--set", default="vsavjw"); ap.add_argument("--pristine", default="vsavj")
a = ap.parse_args()
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
romdir = os.environ.get("ROMDIR") or sys.exit("set ROMDIR")
W = tempfile.mkdtemp(prefix="patch_site_read_")
def decrypt(zipf, out):
    r = subprocess.run([sys.executable, os.path.join(REPO, "tools/cps2_decrypt.py"), zipf, out], capture_output=True, text=True)
    if r.returncode: sys.exit(f"decrypt failed for {zipf}: {r.stderr.strip()[-200:]}")
    return open(out, "rb").read()
def fp(b, flag):
    r = subprocess.run([sys.executable, os.path.join(REPO, "tools/build_fingerprint.py"), f"{b}/rompath", "--set", a.set, flag], capture_output=True, text=True)
    return (r.stdout.strip().split("\n") or ["?"])[-1][:8]
pris = decrypt(os.path.join(romdir, f"{a.pristine}.zip"), os.path.join(W, "pristine.bin"))
sites = [(int(s.split(":", 1)[0], 16), s.split(":", 1)[1]) for s in a.site]
bad = 0
for i, b in enumerate(a.build):
    img = decrypt(os.path.join(b, "rompath", f"{a.set}.zip"), os.path.join(W, f"b{i}.bin"))
    print(f"== {b}   program {fp(b, '--sha-only')}   whole-set {fp(b, '--set-key')}")
    for site, label in sites:
        w = img[site:site + 6]
        if w[:2] == b"\x4e\xf9":
            print(f"   {label} @CPU:${site:06X}: PATCHED  jmp abs.l -> CPU:${int.from_bytes(w[2:6], 'big'):06X}")
        elif w == pris[site:site + 6]:
            print(f"   {label} @CPU:${site:06X}: vanilla  (equal to pristine {a.pristine}'s opcode view, 6 bytes)")
        else:
            print(f"   {label} @CPU:${site:06X}: NEITHER  (not jmp abs.l, and differs from pristine {a.pristine})"); bad += 1
sys.exit(1 if bad else 0)
