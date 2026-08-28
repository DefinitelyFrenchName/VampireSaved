#!/usr/bin/env python3
"""apply_release.py --romdir DIR --out DIR [--manifest manifest.json]

Rebuild a VAMPIRE SAVED romset from a release package and YOUR reference
dumps. Shipped inside every package next to its manifest.json; also lives
in the project tree as tools/apply_release.py (one copy, the packager
copies it).

What it does, in order, failing loudly at the first problem:
  1. verifies every reference member the manifest names (zip, member, size,
     sha1) against your dumps — a wrong dump is reported by name;
  2. builds the source blob exactly as the packager did (fixed zip order,
     members sorted by name) and checks its sha1;
  3. for every target member: copies it pristine from the named reference
     member, or runs `xdelta3 -d -s source.bin patch` and checks the
     result's sha1 against the manifest;
  4. only then writes the output zips (stored, deterministic order).
Nothing is written unless every member verified.
"""
import argparse, hashlib, json, os, shutil, subprocess, sys, tempfile, zipfile


def sha1(b):
    return hashlib.sha1(b).hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--romdir", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--manifest", default=os.path.join(os.path.dirname(
        os.path.abspath(__file__)), "manifest.json"))
    a = ap.parse_args()
    here = os.path.dirname(os.path.abspath(a.manifest))
    m = json.load(open(a.manifest))
    if not shutil.which("xdelta3"):
        sys.exit("xdelta3 not found on PATH")

    # 1. the reference dumps
    refs = {}
    bad = []
    for r in m["source"]["recipe"]:
        zp = os.path.join(a.romdir, r["zip"])
        if not os.path.exists(zp):
            sys.exit(f"missing reference dump: {zp}")
        zf = refs.setdefault(r["zip"], zipfile.ZipFile(zp))
        try:
            d = zf.read(r["member"])
        except KeyError:
            bad.append(f"{r['zip']}/{r['member']}: member missing"); continue
        if len(d) != r["size"] or sha1(d) != r["sha1"]:
            bad.append(f"{r['zip']}/{r['member']}: sha1/size mismatch (wrong or modified dump)")
    if bad:
        sys.exit("reference dumps do not match the manifest:\n  " + "\n  ".join(bad))
    print(f"reference dumps verified: {len(m['source']['recipe'])} members")

    work = tempfile.mkdtemp(prefix="vsaved-apply-")
    try:
        # 2. the source blob
        src = os.path.join(work, "source.bin")
        h = hashlib.sha1()
        with open(src, "wb") as f:
            for z in m["source"]["order"]:
                for n in sorted(refs[z].namelist()):
                    d = refs[z].read(n); f.write(d); h.update(d)
        if h.hexdigest() != m["source"]["sha1"]:
            sys.exit("source blob sha1 mismatch — an extra or missing member in a reference zip")
        print("source blob rebuilt and verified")

        # 3. every target member, verified before anything is written
        built = {}
        for zname, entries in m["zips"].items():
            built[zname] = []
            for e in entries:
                if "pristine_from" in e:
                    d = refs[e["pristine_from"]["zip"]].read(e["pristine_from"]["member"])
                else:
                    pf = os.path.join(here, e["patch"])
                    if not os.path.exists(pf):
                        sys.exit(f"patch missing: {pf}")
                    if sha1(open(pf, "rb").read()) != e["patch_sha1"]:
                        sys.exit(f"patch file corrupted: {e['patch']}")
                    tgt = os.path.join(work, f"{zname}.{e['member']}")
                    subprocess.run(["xdelta3", "-d", "-f", "-s", src, pf, tgt], check=True)
                    d = open(tgt, "rb").read()
                if len(d) != e["size"] or sha1(d) != e["sha1"]:
                    sys.exit(f"{zname}/{e['member']}: rebuilt member does not match the manifest — NOT writing")
                built[zname].append((e["member"], d))
            print(f"  {zname}: {len(entries)} members verified")

        # 4. write
        os.makedirs(a.out, exist_ok=True)
        for zname, ms in built.items():
            with zipfile.ZipFile(os.path.join(a.out, zname), "w", zipfile.ZIP_STORED) as zf:
                for n, d in ms:
                    zi = zipfile.ZipInfo(n, date_time=(1997, 5, 19, 0, 0, 0))
                    zf.writestr(zi, d)
        print(f"OK: wrote {', '.join(sorted(built))} to {a.out} — every member verified "
              f"(build {m.get('build_fingerprint') or '?'}, mark {m.get('version_string')!r})")
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main()
