#!/usr/bin/env python3
"""bundle_dylibs.py — make a macOS binary self-contained: copy every non-system
dynamic library it (transitively) links into ITS OWN directory, rewrite the
install names to @loader_path/<name>, ad-hoc sign everything, and verify that
no absolute non-system reference is left.

Usage: tools/bundle_dylibs.py <dir> <exe> [<exe>...] [--extra <path>:<name>]...

  <dir>   the staging directory; every <exe> must already be inside it
  --extra a library to bundle that no LC_LOAD_DYLIB names, under the given
          name — sdl2-compat dlopen()s SDL3 at run time as
          `@executable_path/libSDL3.dylib` (strings on libSDL2-2.0.0.dylib),
          which otool cannot see.

WHY (14z-149). The EMULATOR.md recipe links FBNeo and MAME against Homebrew's
SDL by ABSOLUTE PATH (/opt/homebrew/opt/sdl3/lib/libSDL3.0.dylib, measured with
otool -L on both binaries), so the binary the recipe produces runs only on a
Mac with the same Homebrew packages at the same prefix. A prebuilt has to carry
its libraries. Everything stays FLAT in one directory (the ruled release
inventory admits `emulator/bin/<os-arch>/<file>` and nothing deeper), so
@loader_path resolves for the executable and for every library alike.

A "system" reference is /usr/lib/... or /System/...; those ship with macOS.
The closure is walked over install names, and each library is copied under the
NAME the loader asks for (libavif.16.dylib), with the CONTENT of the real file
(libavif.16.4.2.dylib) — the two differ for every Homebrew library.

install_name_tool invalidates the code signature, and on Apple Silicon an
unsigned binary does not run at all, so every file is re-signed ad-hoc
(`codesign -s -`). Ad-hoc is not notarization: a downloaded copy is quarantined
and the user opens it once via right-click > Open (BINARY.txt says so).

Prints the inventory (name, size) and exits non-zero on any leftover absolute
reference — the assertion is on the ARTIFACT, not on the tool's intent.
"""
import os
import shutil
import subprocess
import sys


def sh(*args):
    return subprocess.run(args, capture_output=True, text=True, check=True).stdout


def is_macho(path):
    try:
        with open(path, "rb") as f:
            magic = f.read(4)
    except OSError:
        return False
    return magic in (b"\xcf\xfa\xed\xfe", b"\xca\xfe\xba\xbe", b"\xce\xfa\xed\xfe")


def is_system(ref):
    return ref.startswith("/usr/lib/") or ref.startswith("/System/")


def load_refs(path):
    """LC_LOAD_DYLIB (and reexport/weak) paths of one Mach-O, excluding its own id."""
    lines = sh("otool", "-L", path).splitlines()[1:]
    refs = [l.split()[0] for l in lines if l.strip()]
    own = os.path.basename(path)
    return [r for r in refs if os.path.basename(r) != own]


def rpaths(path):
    """LC_RPATH entries of one Mach-O (Homebrew libraries reference siblings as
    @rpath/<name> with the Cellar lib dir as their rpath — measured 14z-149 on
    libjxl, libwebp, brotli; a walk that skips @-prefixed refs leaves them dangling)."""
    out, take = [], False
    for l in sh("otool", "-l", path).splitlines():
        if "cmd LC_RPATH" in l:
            take = True
        elif take and l.strip().startswith("path "):
            out.append(l.split()[1]); take = False
    return out


def needs_bundling(ref):
    return not (is_system(ref) or ref.startswith("@loader_path/") or ref.startswith("@executable_path/"))


def resolve(ref, referrer, srcdir):
    """The real file a reference names: absolute as is; @rpath/<name> through the
    referrer's rpaths, then the directory its source came from."""
    if not ref.startswith("@rpath/"):
        return os.path.realpath(ref)
    name = ref[len("@rpath/"):]
    for rp in rpaths(referrer) + ([srcdir] if srcdir else []):
        cand = os.path.join(rp, name)
        if os.path.exists(cand):
            return os.path.realpath(cand)
    return None


def main(argv):
    if len(argv) < 3:
        sys.exit(__doc__)
    d = os.path.abspath(argv[1])
    exes, extras = [], []
    it = iter(argv[2:])
    for a in it:
        if a == "--extra":
            src, name = next(it).split(":", 1)
            extras.append((src, name))
        else:
            exes.append(os.path.abspath(a))
    for e in exes:
        if os.path.dirname(e) != d:
            sys.exit(f"{e} is not directly inside {d}")

    # 1. the closure, copied flat under the loader's names
    bundled = {}          # name -> path in d
    srcdir = {}           # path in d -> directory the content came from
    todo = list(exes)

    def take(real, name):
        dst = os.path.join(d, name)
        shutil.copy2(real, dst)
        os.chmod(dst, 0o755)
        bundled[name] = dst
        srcdir[dst] = os.path.dirname(real)
        todo.append(dst)

    for src, name in extras:
        take(os.path.realpath(src), name)
    while todo:
        p = todo.pop()
        for ref in load_refs(p):
            if not needs_bundling(ref):
                continue
            name = os.path.basename(ref)
            if name in bundled:
                continue
            real = resolve(ref, p, srcdir.get(p))
            if not real or not os.path.exists(real):
                sys.exit(f"{os.path.basename(p)} links {ref} which cannot be resolved here")
            take(real, name)

    # 2. rewrite install names: every bundled reference -> @loader_path/<name>;
    #    drop the rpaths (they pointed into the Cellar and nothing needs them now)
    allfiles = exes + list(bundled.values())
    for p in allfiles:
        args = []
        for ref in load_refs(p):
            if not needs_bundling(ref):
                continue
            args += ["-change", ref, "@loader_path/" + os.path.basename(ref)]
        for rp in rpaths(p):
            args += ["-delete_rpath", rp]
        if p not in exes:
            args += ["-id", "@loader_path/" + os.path.basename(p)]
        if args:
            subprocess.run(["install_name_tool"] + args + [p], check=True,
                           capture_output=True)
        subprocess.run(["codesign", "-s", "-", "-f", p], check=True, capture_output=True)

    # 3. verify on the artifact
    bad = []
    for p in allfiles:
        for ref in load_refs(p):
            if not (is_system(ref) or ref.startswith("@loader_path/")):
                bad.append((p, ref))
        subprocess.run(["codesign", "--verify", "--strict", p], check=True,
                       capture_output=True)
    for p in sorted(allfiles):
        print(f"  {os.path.getsize(p):>10}  {os.path.basename(p)}")
    if bad:
        for p, ref in bad:
            print(f"LEFTOVER: {os.path.basename(p)} -> {ref}", file=sys.stderr)
        sys.exit(1)
    print(f"bundled {len(bundled)} libraries beside {len(exes)} executable(s); "
          "no absolute non-system reference remains; all ad-hoc signed")


if __name__ == "__main__":
    main(sys.argv)
