#!/usr/bin/env python3
"""bundle_win_dlls.py — make a WINDOWS binary self-contained: copy every
non-system DLL it (transitively) imports into ITS OWN directory, and verify on
the ARTIFACT that every remaining import is either beside the binary or a
Windows system DLL.

Usage: tools/bundle_win_dlls.py <dir> <exe> [<exe>...] [--extra <path>:<name>]...

  <dir>   the staging directory; every <exe> must already be inside it
  --extra a DLL to bundle that no import table names, under the given name —
          sdl2-compat LoadLibrary()s SDL3 at run time (`SDL3.dll`), which no
          import table shows. The macOS and Linux twins do the same.

THE WINDOWS HALF OF THE PREBUILT BINARIES (item 1 of the 14z-149 close; the
macOS twin is tools/bundle_dylibs.py, the Linux one bundle_elf_libs.py).
Same contract, and the mechanism is the simplest of the three:

  macOS    install_name_tool -change ... @loader_path/<name>, ad-hoc signed
  Linux    patchelf --set-rpath '$ORIGIN'
  WINDOWS  NOTHING TO REWRITE                                    <- here

A PE import table names a DLL by bare name (`SDL2.dll`), never by path, and
the loader searches the directory of the executable FIRST. So a DLL copied
beside the .exe is found by the exe and by every other bundled DLL, with no
install names, no RUNPATH and no re-signing. There is also no ad-hoc
signature to apply: Windows has no equivalent of `codesign -s -`, so the
record's sha256 rows are the whole integrity story for this platform
(BINARY.txt says so in its own words, and the gate asserts the rows rather
than a signature on this OS).

WRITTEN WITHOUT A WINDOWS HOST TO RUN IT ON, and stated rather than hidden:
the first MSYS2 session runs it, and `tests/test_bundle_parsers.sh` proves
the parser reads real `ldd` / `objdump -p` output instead of returning an
empty closure ([VSP-148]). An EMPTY closure is a hard error here too — the
recipe links SDL out of MSYS2's package manager, so a binary with nothing to
bundle means the parse failed, not that it is standalone.

WHAT IS DELIBERATELY NOT BUNDLED: the Windows system DLLs (KERNEL32,
USER32, GDI32, OPENGL32, the CRT forwarders in api-ms-win-*, …). They are the
operating system; a copy from the build machine is at best redundant and at
worst a version conflict. Everything from the MSYS2 prefix IS bundled — the
SDL2/SDL3 pair, SDL2_image and its codecs, libwinpthread, libstdc++-6 and
libgcc_s_seh — because a player's Windows has no MSYS2 installed, which is
the whole point of a prebuilt.

Run it from an MSYS2 shell (MINGW64 or UCRT64), the same environment the
recipe builds in: it needs that shell's `ldd` and `objdump`.
"""
import os
import re
import shutil
import subprocess
import sys

# Import names that are the OS itself even when nothing resolves them. The
# api-ms-win-* / ext-ms-win-* API SETS are prefixes with a versioned tail
# (api-ms-win-crt-stdio-l1-1-0.dll), so they are matched separately from the
# named DLLs — folding them into one alternation anchored at `\.dll$` silently
# matched none of them (caught by tests/test_bundle_parsers.sh on its first run).
SYSTEM_PREFIX_RE = re.compile(r"^(?:api-ms-win-|ext-ms-win-)", re.IGNORECASE)
SYSTEM_DLL_RE = re.compile(
    r"^(?:kernel32|kernelbase|user32|gdi32|gdiplus|advapi32|"
    r"shell32|shlwapi|ole32|oleaut32|comctl32|comdlg32|ws2_32|wsock32|winmm|"
    r"opengl32|glu32|dwmapi|uxtheme|version|imm32|setupapi|cfgmgr32|hid|"
    r"dxgi|d3d9|d3d11|d3d12|dinput8|dsound|xinput[0-9_]*|avrt|"
    r"msvcrt|ucrtbase|vcruntime[0-9]*|msvcp[0-9]*|crypt32|bcrypt|ntdll|rpcrt4|"
    r"secur32|mpr|iphlpapi|netapi32|powrprof|propsys|psapi|userenv|usp10|"
    r"winspool|wintrust|wtsapi32)\.dll$", re.IGNORECASE)


def is_system_dll(name):
    """A Windows system DLL: an api-set prefix, or one of the named OS libraries."""
    base = os.path.basename(name)
    return bool(SYSTEM_PREFIX_RE.match(base) or SYSTEM_DLL_RE.match(base))


def sh(*args):
    return subprocess.run(args, capture_output=True, text=True, check=True).stdout


def is_pe(path):
    """A PE file starts 'MZ' and carries a PE header pointer at 0x3C."""
    try:
        with open(path, "rb") as f:
            if f.read(2) != b"MZ":
                return False
            f.seek(0x3C)
            off = int.from_bytes(f.read(4), "little")
            f.seek(off)
            return f.read(4) == b"PE\x00\x00"
    except OSError:
        return False


def system_path(path):
    """True when a resolved path is inside the Windows directory."""
    if not path:
        return False
    p = path.replace("\\", "/")
    return bool(re.match(r"^(?:[a-zA-Z]:/|/[a-zA-Z]/)?(?:WINDOWS|WinNT)/", p, re.IGNORECASE))


def parse_ldd(text):
    """MSYS2's `ldd` on a PE binary: {dll name: resolved path or None}.

        SDL2.dll => /mingw64/bin/SDL2.dll (0x...)
        KERNEL32.DLL => /c/WINDOWS/System32/KERNEL32.DLL (0x...)
        ??? => ??? (0x...)                    <- unresolvable, ignored by name
        libfoo.dll => not found               <- REPORTED with a None path
    """
    out = {}
    for line in text.splitlines():
        line = line.strip()
        if "=>" not in line:
            continue
        left, right = line.split("=>", 1)
        name = left.strip()
        right = right.strip()
        if name in ("???", ""):
            continue
        if right.startswith("not found"):
            out[name] = None
            continue
        path = re.sub(r"\s*\(0x[0-9a-fA-F]+\)$", "", right).strip()
        if path and path != "???":
            out[name] = path
    return out


def parse_imports(text):
    """Imported DLL names from `objdump -p` output:

        DLL Name: SDL2.dll
    """
    return re.findall(r"^\s*DLL Name:\s*(\S+)\s*$", text, re.M)


def main(argv):
    if len(argv) < 3:
        sys.exit(__doc__)
    for tool in ("ldd", "objdump"):
        if not shutil.which(tool):
            sys.exit(f"{tool} is not on PATH — run this from an MSYS2 MINGW64/UCRT64 shell "
                     "(pacman -S mingw-w64-x86_64-binutils)")
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

    # 1. the closure, copied flat beside the executable (no rewriting: the
    #    loader searches the .exe's own directory first)
    bundled = {}
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
        missing = [n for n, path in resolved.items()
                   if path is None and not is_system_dll(n)]
        if missing:
            sys.exit(f"{os.path.basename(p)} imports {', '.join(missing)} which ldd cannot "
                     "resolve here — the build environment is missing a package the recipe linked")
        for name in parse_imports(sh("objdump", "-p", p)):
            key = os.path.basename(name)
            if is_system_dll(key) or key in bundled:
                continue
            # resolve case-insensitively: import tables and ldd disagree on case
            real = resolved.get(name) or next(
                (v for k, v in resolved.items() if k.lower() == name.lower()), None)
            if not real:
                sys.exit(f"{os.path.basename(p)} imports {name}, which ldd did not resolve")
            if system_path(real):
                continue                      # a Windows DLL under another name
            if not os.path.exists(real):
                sys.exit(f"{os.path.basename(p)} imports {name} at {real}, which does not exist")
            take(os.path.realpath(real), key)

    if not bundled:
        sys.exit("REFUSING: the closure is EMPTY — ldd/objdump returned nothing to bundle, "
                 "which on this recipe means the parse failed, not that the .exe is standalone")

    # 2. verify on the ARTIFACT: every import of every file is bundled or the OS's
    allfiles = exes + sorted(bundled.values())
    have = {k.lower() for k in bundled}
    bad = []
    for p in allfiles:
        for name in parse_imports(sh("objdump", "-p", p)):
            key = os.path.basename(name).lower()
            if is_system_dll(name) or key in have:
                continue
            bad.append((p, name))
    for p in sorted(allfiles):
        print(f"  {os.path.getsize(p):>10}  {os.path.basename(p)}")
    if bad:
        for p, name in bad:
            print(f"LEFTOVER: {os.path.basename(p)} imports {name}, which is neither bundled "
                  "nor a Windows system DLL", file=sys.stderr)
        sys.exit(1)
    print(f"bundled {len(bundled)} DLLs beside {len(exes)} executable(s); "
          "every import resolves beside the binary or to Windows itself "
          "(no signature on this platform — the sha256 rows are the integrity)")


if __name__ == "__main__":
    main(sys.argv)
