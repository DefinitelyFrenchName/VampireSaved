#!/usr/bin/env python3
"""bundle_elf_libs.py — make a LINUX binary self-contained: copy every
non-system shared library it (transitively) needs into ITS OWN directory, set
every file's RUNPATH to $ORIGIN, and verify on the ARTIFACT that nothing is
left pointing outside this directory and the host's own runtime.

Usage: tools/bundle_elf_libs.py <dir> <exe> [<exe>...] [--extra <path>:<name>]...

  <dir>   the staging directory; every <exe> must already be inside it
  --extra a library to bundle that no DT_NEEDED entry names, under the given
          name — sdl2-compat dlopen()s SDL3 at run time (`libSDL3.so.0`),
          which ldd cannot see. The macOS twin does the same.

THE LINUX HALF OF THE PREBUILT BINARIES (item 1 of the 14z-149 close; the
macOS twin is tools/bundle_dylibs.py, the Windows one bundle_win_dlls.py).
Same contract, three mechanisms:

  macOS    install_name_tool -change ... @loader_path/<name>, ad-hoc signed
  LINUX    patchelf --set-rpath '$ORIGIN'   <- here
  Windows  nothing to rewrite (the loader searches the .exe's own directory)

WRITTEN WITHOUT A LINUX HOST TO RUN IT ON, and that is stated rather than
hidden: the first Linux session runs it, and `tests/test_bundle_parsers.sh`
is what proves the two parsers below read real `ldd` / `readelf` output
rather than returning a tidy empty closure ([VSP-148] — a measurement that
comes back clean is a bug report about the measurement until proven
otherwise). Every stage asserts on the artifact, and an EMPTY closure is a
hard error: a bundler that bundles nothing and then finds no leftovers would
otherwise report success on a binary that runs only on the build host, which
is the exact failure this tool exists to prevent.

WHAT IS DELIBERATELY NOT BUNDLED, and why it is not an oversight. A Linux
binary must inherit part of its runtime from the host or it breaks:

  * the glibc family (ld-linux, libc, libm, libdl, libpthread, librt,
    libresolv, libutil, libcrypt, libnsl) — the loader and the C library are
    one unit with the kernel's syscall ABI; a bundled libc against the host's
    ld.so is the classic way to make a binary that segfaults at startup. The
    floor is therefore the BUILD HOST's glibc, measured below and written
    into BINARY.txt's `requires` line: build on the OLDEST distribution you
    intend to support (glibc is backward compatible, never forward).
  * the GPU and display stack (libGL, libGLX, libGLdispatch, libEGL,
    libOpenGL, libGLESv*, libglapi, libdrm, libgbm) — these are the entry
    points to the USER'S graphics driver and load driver modules behind the
    scenes; a bundled libGL from another distribution silently disables
    acceleration or fails to find the driver at all.
  * the display-server and device clients (libX11, libxcb*, libwayland-*,
    libudev, libdbus-1, libsystemd) and the audio clients (libasound,
    libpulse, libpipewire*) — each dlopen()s host-side modules and talks to
    a host daemon over a socket whose protocol belongs to the host.
  * libstdc++ / libgcc_s — bundling these is safe ONLY when the build
    compiler is newer than every target's; excluded here so the artifact
    states one honest floor (the distribution's toolchain) instead of two.

Everything else — SDL and the image codecs FBNeo drags in, which is exactly
what the recipe links out of the build host's package manager — IS bundled,
because that is the set a player's machine has no reason to carry.

Prints the inventory (size, name) and exits non-zero on any leftover
reference. Needs `patchelf` (Debian/Ubuntu: apt install patchelf).
"""
import os
import re
import shutil
import subprocess
import sys

# Left to the host. Matched against the SONAME's stem (libfoo.so.1 -> libfoo),
# so a version suffix never smuggles one past the list.
SYSTEM_STEMS = {
    # the loader and the C library: one unit with the kernel ABI
    "ld-linux", "ld-linux-x86-64", "ld-linux-aarch64", "ld64",
    "libc", "libm", "libdl", "libpthread", "librt", "libresolv",
    "libutil", "libcrypt", "libnsl", "libanl",
    # the compiler runtime (see the header: one honest floor, not two)
    "libstdc++", "libgcc_s",
    # the user's GPU driver entry points and their module loaders
    "libGL", "libGLX", "libGLdispatch", "libEGL", "libOpenGL", "libglapi",
    "libGLESv1_CM", "libGLESv2", "libdrm", "libgbm",
    # display server / device / audio clients: host daemons and host modules
    "libX11", "libX11-xcb", "libXext", "libXcursor", "libXi", "libXrandr",
    "libXfixes", "libXrender", "libXss", "libXxf86vm", "libXinerama",
    "libwayland-client", "libwayland-egl", "libwayland-cursor",
    "libudev", "libdbus-1", "libsystemd", "libcap",
    "libasound", "libpulse", "libpulse-simple", "libjack",
}
# libxcb, libxcb-shm, libxcb-randr ... — one family, matched by prefix.
SYSTEM_PREFIXES = ("libxcb", "libpipewire", "libspa-")


def sh(*args):
    return subprocess.run(args, capture_output=True, text=True, check=True).stdout


def soname_stem(name):
    """libavif.so.16.4.2 -> libavif ; ld-linux-x86-64.so.2 -> ld-linux-x86-64"""
    return re.sub(r"\.so.*$", "", os.path.basename(name))


def is_system(name):
    stem = soname_stem(name)
    return stem in SYSTEM_STEMS or stem.startswith(SYSTEM_PREFIXES)


def is_elf(path):
    try:
        with open(path, "rb") as f:
            return f.read(4) == b"\x7fELF"
    except OSError:
        return False


def parse_ldd(text):
    """The resolved libraries of one `ldd` run: {soname: path or None}.

    Three line shapes, and the third is the one that matters:
        libfoo.so.1 => /usr/lib/x86_64-linux-gnu/libfoo.so.1 (0x...)
        linux-vdso.so.1 (0x...)                         <- no '=>': kernel/loader, skip
        libbar.so.2 => not found                        <- REPORTED, never skipped
    (the load addresses are elided on purpose: a literal one reads as a
    program address to tools/gen_annotations.py and lands in the address index)
    A `not found` line is a broken build, not a library to leave to the host:
    it is returned with a None path so the caller fails loudly.
    """
    out = {}
    for line in text.splitlines():
        line = line.strip()
        if "=>" not in line:
            continue                      # vdso and the loader itself
        left, right = line.split("=>", 1)
        soname = left.strip()
        right = right.strip()
        if right.startswith("not found"):
            out[soname] = None
            continue
        path = re.sub(r"\s*\(0x[0-9a-f]+\)$", "", right).strip()
        if path:
            out[soname] = path
    return out


def parse_needed(text):
    """DT_NEEDED sonames from `readelf -d` (or `objdump -p`) output.

      0x0000000000000001 (NEEDED)  Shared library: [libSDL2-2.0.so.0]
      NEEDED               libSDL2-2.0.so.0
    """
    out = []
    for line in text.splitlines():
        m = re.search(r"\(NEEDED\)\s+Shared library:\s+\[([^\]]+)\]", line)
        if not m:
            m = re.match(r"\s*NEEDED\s+(\S+)\s*$", line)
        if m:
            out.append(m.group(1))
    return out


def parse_runpath(text):
    """The DT_RUNPATH / DT_RPATH value from `readelf -d` output, or ''."""
    for line in text.splitlines():
        m = re.search(r"\((?:RUNPATH|RPATH)\)\s+Library (?:runpath|rpath):\s+\[([^\]]*)\]", line)
        if m:
            return m.group(1)
    return ""


def readelf_d(path):
    return sh("readelf", "-d", path)


def glibc_floor(paths):
    """The highest GLIBC_x.y version symbol the artifacts require — the honest
    `requires` line, measured like macOS's LC_BUILD_VERSION minos rather than
    assumed. Backward compatible, never forward: build on the oldest LTS you
    mean to support."""
    best = (0, 0)
    for p in paths:
        try:
            out = sh("readelf", "-V", p)
        except subprocess.CalledProcessError:
            continue
        for major, minor in re.findall(r"GLIBC_(\d+)\.(\d+)", out):
            best = max(best, (int(major), int(minor)))
    return f"{best[0]}.{best[1]}" if best != (0, 0) else "unknown"


def main(argv):
    if len(argv) < 3:
        sys.exit(__doc__)
    if not shutil.which("patchelf"):
        sys.exit("patchelf is not installed (Debian/Ubuntu: sudo apt install patchelf)")
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

    # 1. the closure, copied flat under the SONAME the loader asks for
    bundled = {}
    needed_seen = [0]          # how many NEEDED entries the tools reported at all
    todo = list(exes)

    def take(real, name):
        dst = os.path.join(d, name)
        shutil.copy2(real, dst)
        os.chmod(dst, 0o755)
        bundled[name] = dst
        todo.append(dst)

    for src, name in extras:
        real = os.path.realpath(src)
        if not os.path.exists(real):
            sys.exit(f"--extra {src} does not exist")
        take(real, name)

    while todo:
        p = todo.pop()
        resolved = parse_ldd(sh("ldd", p))
        missing = [s for s, path in resolved.items() if path is None and not is_system(s)]
        if missing:
            sys.exit(f"{os.path.basename(p)} needs {', '.join(missing)} which ldd cannot resolve "
                     "here — the build host is missing a package the recipe linked against")
        _needed = parse_needed(readelf_d(p))
        needed_seen[0] += len(_needed)
        for soname in _needed:
            if is_system(soname) or soname in bundled:
                continue
            real = resolved.get(soname)
            if not real or not os.path.exists(real):
                sys.exit(f"{os.path.basename(p)} needs {soname}, which ldd did not resolve")
            take(os.path.realpath(real), soname)

    # AN EMPTY CLOSURE HAS TWO OPPOSITE CAUSES and only one is a defect (the
    # discriminator added 2026-09-12, after the Windows twin refused MAME's
    # genuinely static build): no NEEDED entries AT ALL means the instrument is
    # broken and "self-contained" would be vacuous; NEEDED entries that are all
    # host libraries by policy (glibc, the GPU/X11/audio stacks) means there is
    # honestly nothing to carry. The Linux recipe links SDL dynamically, so the
    # second is not expected here — but it is REPORTED rather than called a
    # failure, because the check's job is to tell the two apart.
    if not bundled:
        if needed_seen[0] == 0:
            sys.exit("REFUSING: the tools reported NO dependencies at all — ldd/readelf "
                     "returned nothing, which means the parse failed, not that the "
                     "binary is static")
        print(f"nothing to bundle: {needed_seen[0]} dependency entr(ies), every one a host "
              "library by policy — check that against what this recipe links")

    # 2. every file looks beside itself, and nowhere else. $ORIGIN is the
    #    loader's spelling of @loader_path; --force-rpath is deliberate only
    #    in that we do not care which tag it writes — the verifier below reads
    #    whichever one landed.
    allfiles = exes + sorted(bundled.values())
    for p in allfiles:
        subprocess.run(["patchelf", "--set-rpath", "$ORIGIN", p], check=True,
                       capture_output=True)
        if p not in exes:
            subprocess.run(["patchelf", "--set-soname", os.path.basename(p), p],
                           check=True, capture_output=True)

    # 3. verify on the ARTIFACT
    bad = []
    for p in allfiles:
        dyn = readelf_d(p)
        run = parse_runpath(dyn)
        if run != "$ORIGIN":
            bad.append((p, f"RUNPATH is {run!r}, expected '$ORIGIN'"))
        for soname in parse_needed(dyn):
            if is_system(soname) or soname in bundled:
                continue
            bad.append((p, f"needs {soname}, which is neither bundled nor a host library"))
    for p in sorted(allfiles):
        print(f"  {os.path.getsize(p):>10}  {os.path.basename(p)}")
    if bad:
        for p, why in bad:
            print(f"LEFTOVER: {os.path.basename(p)} {why}", file=sys.stderr)
        sys.exit(1)
    print(f"bundled {len(bundled)} libraries beside {len(exes)} executable(s); "
          f"RUNPATH=$ORIGIN on every file; glibc floor {glibc_floor(allfiles)}")


if __name__ == "__main__":
    main(sys.argv)
