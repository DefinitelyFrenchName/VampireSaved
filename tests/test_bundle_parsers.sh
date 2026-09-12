#!/bin/sh
# test_bundle_parsers.sh — the LINUX and WINDOWS library bundlers
# (tools/bundle_elf_libs.py, tools/bundle_win_dlls.py) read real `ldd`,
# `readelf -d` and `objdump -p` output, walk a closure, and REFUSE an empty
# one. ROM-free, no emulator, ~2 s.
#
# MUST-FIRE: shadow-tool: empty-closure — a stub toolchain that reports NO libraries must make each bundler REFUSE, never report a self-contained binary (mode: a COPY of both bundlers with the refusal removed must make section 2 fail)
# MUST-FIRE: shadow-tool: msys-path-untranslated — a COPY of the Windows bundler with the MSYS-path translation disabled must FAIL section 4: `ldd` answers in MSYS's namespace (`/mingw64/bin/x.dll`) and the native Windows python cannot open that, so every resolved DLL would read as missing
# MUST-FIRE: shadow-tool: unbundled-leftover — a stub readelf reporting a NEEDED library that is neither bundled nor a host library must make the Linux bundler's ARTIFACT check fail (mode: a COPY with the artifact check neutered must make the control section fail)
#
# WHY THIS GATE EXISTS, and what it does NOT claim. The two bundlers were
# written on a MacBook with no Linux and no Windows host to run them on
# (item 1 of the 14z-149 close: the maintainer builds those on their own
# machines, under WSL2 / MSYS2). Untestable code that ships is how a release
# host discovers a typo instead of a binary. So the OS-INDEPENDENT half — the
# parsers, the closure walk, the refusal, the artifact check — is exercised
# HERE against recorded tool output and against stub tools on PATH, exactly
# the way bbh's FAKE MACHINE gives every expectation class a ROM-free
# producer.
#
# IT DOES NOT CLAIM the binaries work: `patchelf --set-rpath` actually
# rewriting an ELF, the Windows loader actually finding a DLL beside the
# .exe, and the excluded-system-library policy being RIGHT are all facts
# about a real host, and only `tests/test_release_binaries.sh` running there
# can say so. What it does claim is that neither tool can come back quiet.
#
# THE FAILURE IT IS AIMED AT is [VSP-148]'s: a parser that returns nothing
# makes a bundler "succeed" with an empty closure, after which the verifier
# finds no leftovers and prints success — a vacuous green on a binary that
# runs only on the build host, which is the one thing these tools exist to
# prevent. Both bundlers therefore hard-refuse an empty closure, and section
# 2 is that refusal, run.
#
# Usage: tests/test_bundle_parsers.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0

# THE TOOLS UNDER TEST. A control mode replaces them with a COPY carrying ONE
# guard removed — the perturbation is applied to the REAL input and the gate
# runs to its own verdict, which must be FAIL ([VSP-181]).
TOOLS="$REPO/tools"
shadow_tools() {  # shadow_tools <expression-to-disable> [replacement]  -> $W/tools
    mkdir -p "$W/tools"
    cp "$REPO/tools/bundle_elf_libs.py" "$REPO/tools/bundle_win_dlls.py" "$W/tools/"
    python3 - "$W/tools" "$1" "${2:-if False:}" <<'SPY'
import pathlib, sys
d, guard, repl = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
for f in sorted(d.glob("bundle_*.py")):
    t = f.read_text()
    if guard in t:
        f.write_text(t.replace(guard, repl))
        print(f"  mode: {f.name} with `{guard}` -> `{repl}`")
SPY
    TOOLS="$W/tools"
}
vs_ctl_is empty-closure     && shadow_tools "if not bundled:"
vs_ctl_is unbundled-leftover && shadow_tools "if bad:"
# the translation neutered: winpath() returns its argument, which is what a
# native-Windows python did with an MSYS path before 2026-09-12
vs_ctl_is msys-path-untranslated && shadow_tools 'if not path or not path.startswith("/"):' "if True:"

# ---- section 1: the parsers, against RECORDED tool output ------------------
echo "== 1. parsers vs recorded ldd / readelf / objdump output"
python3 - "$REPO" <<'PY' || fail=1
import sys
sys.path.insert(0, sys.argv[1] + "/tools")
import bundle_elf_libs as elf
import bundle_win_dlls as win

bad = []
def eq(what, got, want):
    if got != want:
        bad.append(f"{what}: got {got!r}, want {want!r}")

# --- Linux: ldd(1) on an Ubuntu host. Four line shapes, and every one of them
#     has a history: the vdso and the loader carry no '=>' and are NOT
#     libraries; a 'not found' must survive the parse so the caller can fail.
LDD = """\
\tlinux-vdso.so.1 (0x00007ffd1d5f8000)
\tlibSDL2-2.0.so.0 => /lib/x86_64-linux-gnu/libSDL2-2.0.so.0 (0x00007f8e4c000000)
\tlibSDL2_image-2.0.so.0 => /lib/x86_64-linux-gnu/libSDL2_image-2.0.so.0 (0x00007f8e4be00000)
\tlibc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f8e4b800000)
\tlibmissing.so.3 => not found
\t/lib64/ld-linux-x86-64.so.2 (0x00007f8e4d0a2000)
"""
got = elf.parse_ldd(LDD)
eq("ldd: resolved count", len(got), 4)
eq("ldd: SDL2 path", got.get("libSDL2-2.0.so.0"), "/lib/x86_64-linux-gnu/libSDL2-2.0.so.0")
eq("ldd: not-found is reported with a None path", "libmissing.so.3" in got and got["libmissing.so.3"], None)
eq("ldd: the vdso is not a library", "linux-vdso.so.1" in got, False)
eq("ldd: the loader is not a library", any("ld-linux" in k for k in got), False)

# --- Linux: readelf -d, and the objdump -p spelling of the same table
READELF = """\
Dynamic section at offset 0x2d58 contains 27 entries:
  Tag        Type                         Name/Value
 0x0000000000000001 (NEEDED)             Shared library: [libSDL2-2.0.so.0]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
 0x000000000000001d (RUNPATH)            Library runpath: [$ORIGIN]
 0x000000000000000c (INIT)               0x4000
"""
eq("readelf: NEEDED", elf.parse_needed(READELF), ["libSDL2-2.0.so.0", "libc.so.6"])
eq("readelf: RUNPATH", elf.parse_runpath(READELF), "$ORIGIN")
eq("readelf: no RUNPATH -> ''", elf.parse_runpath("Dynamic section\n"), "")
eq("readelf: RPATH is read too",
   elf.parse_runpath(" 0x0f (RPATH)  Library rpath: [/opt/x]\n"), "/opt/x")
eq("objdump: the bare NEEDED spelling",
   elf.parse_needed("  NEEDED               libfoo.so.1\n"), ["libfoo.so.1"])

# --- Linux: what is left to the host. A version suffix must never smuggle a
#     system library past the list, which is why the stem is what is matched.
for name in ("libc.so.6", "libm.so.6", "libGL.so.1", "libX11.so.6",
             "libxcb-randr.so.0", "libstdc++.so.6", "ld-linux-x86-64.so.2",
             "libasound.so.2", "libdrm.so.2"):
    if not elf.is_system(name):
        bad.append(f"is_system({name}) should be True — bundling it breaks the host runtime")
for name in ("libSDL2-2.0.so.0", "libSDL2_image-2.0.so.0", "libpng16.so.16",
             "libwebp.so.7", "libjxl.so.0.12", "libzstd.so.1"):
    if elf.is_system(name):
        bad.append(f"is_system({name}) should be False — a player's machine has no reason to carry it")

# --- Windows: MSYS2's ldd on a PE binary, and objdump -p's import table
WLDD = """\
\tntdll.dll => /c/WINDOWS/SYSTEM32/ntdll.dll (0x7ffb12340000)
\tKERNEL32.DLL => /c/WINDOWS/System32/KERNEL32.DLL (0x7ffb11110000)
\tSDL2.dll => /mingw64/bin/SDL2.dll (0x6fc40000)
\tlibwinpthread-1.dll => /mingw64/bin/libwinpthread-1.dll (0x64940000)
\t??? => ??? (0x7ffb11000000)
"""
g = win.parse_ldd(WLDD)
eq("win ldd: count", len(g), 4)
eq("win ldd: SDL2 path", g.get("SDL2.dll"), "/mingw64/bin/SDL2.dll")
eq("win ldd: the ??? line is dropped", "???" in g, False)
eq("win ldd: a system dll resolves under the Windows dir",
   win.system_path(g["ntdll.dll"]), True)
eq("win ldd: an MSYS2 dll does not", win.system_path(g["SDL2.dll"]), False)
eq("win objdump: imports",
   win.parse_imports("\tDLL Name: KERNEL32.dll\n\tDLL Name: SDL2.dll\n"),
   ["KERNEL32.dll", "SDL2.dll"])
for n in ("KERNEL32.dll", "USER32.dll", "OPENGL32.dll", "api-ms-win-crt-stdio-l1-1-0.dll",
          "msvcrt.dll", "ucrtbase.dll", "ntdll.dll"):
    if not win.is_system_dll(n):
        bad.append(f"{n} should be classed a Windows system DLL")
for n in ("SDL2.dll", "SDL2_image.dll", "libwinpthread-1.dll", "libstdc++-6.dll"):
    if win.is_system_dll(n):
        bad.append(f"{n} should NOT be classed a Windows system DLL — it must ship")

if bad:
    print("\n".join("FAIL: " + b for b in bad))
    sys.exit(1)
print("  ok: 4 ldd shapes, both NEEDED spellings, RUNPATH/RPATH, both system classifiers")
PY

# ---- the stub toolchain: `ldd`, `readelf`, `objdump`, `patchelf` on PATH ----
# One function, called by the control section and by the CONTROL= modes, so
# what the mode proves is what the control claims ([VSP-181]).
make_stubs() {  # make_stubs <dir> <mode: full|silent|leftover>
    sdir="$1"; mode="$2"; mkdir -p "$sdir"
    cat > "$sdir/ldd" <<EOF
#!/bin/sh
# resolve only what the fixture below declares; anything else is "not found"
case "\$(basename "\$1")" in
fbneo|fbneo.exe)
    [ "$mode" = silent ] && exit 0
    printf '\tlinux-vdso.so.1 (0x00007ffd00000000)\n'
    printf '\tlibSDL2-2.0.so.0 => %s/libSDL2-2.0.so.0 (0x00007f0000000000)\n' "$W/sys"
    printf '\tlibc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f0100000000)\n'
    if [ "$mode" = msyspath ]; then
        # MSYS2's OWN namespace, which is what the real ldd answers with
        printf '\tSDL2.dll => /mingw64/bin/SDL2.dll (0x6fc40000)\n'
    else
        printf '\tSDL2.dll => %s/SDL2.dll (0x6fc40000)\n' "$W/sys"
    fi
    printf '\tKERNEL32.DLL => /c/WINDOWS/System32/KERNEL32.DLL (0x7ffb11110000)\n'
    ;;
libSDL2-2.0.so.0|SDL2.dll)
    printf '\tlibpng16.so.16 => %s/libpng16.so.16 (0x00007f0200000000)\n' "$W/sys"
    if [ "$mode" = msyspath ]; then
        printf '\tlibpng16.dll => /mingw64/bin/libpng16.dll (0x6f000000)\n'
    else
        printf '\tlibpng16.dll => %s/libpng16.dll (0x6f000000)\n' "$W/sys"
    fi
    printf '\tlibc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f0100000000)\n'
    ;;
*)  printf '\tlibc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f0100000000)\n' ;;
esac
EOF
    cat > "$sdir/readelf" <<EOF
#!/bin/sh
# \$1 is -d or -V, \$2 the file
f="\$(basename "\$2")"
[ "\$1" = -V ] && { printf 'GLIBC_2.17\nGLIBC_2.34\n'; exit 0; }
[ "$mode" = silent ] && exit 0
case "\$f" in
fbneo)   printf ' 0x01 (NEEDED) Shared library: [libSDL2-2.0.so.0]\n'
         printf ' 0x01 (NEEDED) Shared library: [libc.so.6]\n' ;;
libSDL2-2.0.so.0)
         printf ' 0x01 (NEEDED) Shared library: [libpng16.so.16]\n' ;;
libpng16.so.16)
         # only AFTER patchelf ran (marker present) = the artifact check, never the walk
         if [ "$mode" = leftover ] && [ -f "\$(dirname "\$2")/.rpath.\$f" ]; then
             printf ' 0x01 (NEEDED) Shared library: [libghost.so.9]\n'
         fi ;;
esac
# after patchelf ran, the runpath is what it wrote
[ -f "\$(dirname "\$2")/.rpath.\$f" ] && printf ' 0x1d (RUNPATH) Library runpath: [%s]\n' "\$(cat "\$(dirname "\$2")/.rpath.\$f")"
exit 0
EOF
    cat > "$sdir/objdump" <<EOF
#!/bin/sh
f="\$(basename "\$2")"
[ "$mode" = silent ] && exit 0
case "\$f" in
fbneo.exe) printf '\tDLL Name: KERNEL32.dll\n\tDLL Name: SDL2.dll\n' ;;
SDL2.dll)  printf '\tDLL Name: libpng16.dll\n' ;;
esac
exit 0
EOF
    cat > "$sdir/patchelf" <<'EOF'
#!/bin/sh
# record what would have been written, so the stub readelf can read it back
case "$1" in
--set-rpath) echo "$2" > "$(dirname "$3")/.rpath.$(basename "$3")" ;;
esac
exit 0
EOF
    # MSYS2's own path translator, the only authority on its namespace
    cat > "$sdir/cygpath" <<EOF
#!/bin/sh
# -w <posix> -> the native path; the fixture maps /mingw64/bin onto \$W/sys
case "\$2" in
/mingw64/bin/*) printf '%s/%s\n' "$W/sys" "\$(basename "\$2")" ;;
*)              printf '%s\n' "\$2" ;;
esac
EOF
    chmod +x "$sdir"/*
}

mkdir -p "$W/sys"
for f in libSDL2-2.0.so.0 libpng16.so.16 SDL2.dll libpng16.dll; do
    printf 'stub library %s\n' "$f" > "$W/sys/$f"
done

run_bundler() {  # run_bundler <tool> <exe-name> <stub-mode> <outdir>  -> exit status
    make_stubs "$W/stub_$3" "$3"
    rm -rf "$4"; mkdir -p "$4"
    printf 'stub executable\n' > "$4/$2"
    chmod +x "$4/$2"
    ( PATH="$W/stub_$3:$PATH" python3 "$TOOLS/$1" "$4" "$4/$2" ) > "$4/out.txt" 2>&1
}

# ---- section 2: an EMPTY closure is REFUSED by both bundlers ---------------
echo "== 2. the empty-closure refusal (the vacuous-green guard)"
for pair in "bundle_elf_libs.py fbneo" "bundle_win_dlls.py fbneo.exe"; do
    tool="${pair%% *}"; exe="${pair##* }"
    if run_bundler "$tool" "$exe" silent "$W/empty_$tool"; then
        echo "FAIL: $tool reported SUCCESS on an empty closure — a binary that runs only on the build host"
        fail=1
    elif grep -q 'REFUSING: the closure is EMPTY' "$W/empty_$tool/out.txt"; then
        echo "  ok: $tool refuses an empty closure"
    else
        echo "FAIL: $tool failed for the wrong reason:"; sed 's/^/        /' "$W/empty_$tool/out.txt"; fail=1
    fi
done

# ---- section 3: a full simulated bundle ------------------------------------
echo "== 3. the closure walk, the copy, and the artifact check"
if run_bundler bundle_elf_libs.py fbneo full "$W/lin"; then
    for lib in libSDL2-2.0.so.0 libpng16.so.16; do
        [ -f "$W/lin/$lib" ] || { echo "FAIL: linux bundle lacks $lib (transitive closure not walked)"; fail=1; }
    done
    if [ -f "$W/lin/libc.so.6" ]; then
        echo "FAIL: linux bundle CONTAINS libc.so.6 — the host runtime must not be bundled"; fail=1
    fi
    [ "$(cat "$W/lin/.rpath.fbneo" 2>/dev/null)" = '$ORIGIN' ] \
        || { echo "FAIL: patchelf was not asked for RUNPATH=\$ORIGIN on the executable"; fail=1; }
    grep -q 'glibc floor 2.34' "$W/lin/out.txt" \
        || { echo "FAIL: the glibc floor was not measured from readelf -V:"; tail -2 "$W/lin/out.txt"; fail=1; }
else
    echo "FAIL: the linux bundler failed on a resolvable closure:"; sed 's/^/        /' "$W/lin/out.txt"; fail=1
fi
if run_bundler bundle_win_dlls.py fbneo.exe full "$W/win"; then
    for dll in SDL2.dll libpng16.dll; do
        [ -f "$W/win/$dll" ] || { echo "FAIL: windows bundle lacks $dll (transitive closure not walked)"; fail=1; }
    done
    if [ -f "$W/win/KERNEL32.DLL" ]; then
        echo "FAIL: windows bundle CONTAINS KERNEL32.DLL — the OS must not be bundled"; fail=1
    fi
else
    echo "FAIL: the windows bundler failed on a resolvable closure:"; sed 's/^/        /' "$W/win/out.txt"; fail=1
fi
[ "$fail" = 0 ] && echo "  ok: both closures walked transitively, host libraries left out, \$ORIGIN requested"

# ---- section 4: MSYS2 answers in ITS OWN namespace --------------------------
# The blind spot that let a real host find this first: every stub until now
# handed back a path that already existed, so the translation was never needed
# and never exercised. The real `ldd` is an MSYS program and answers
# `/mingw64/bin/x.dll`; the python the recipe installs is a native Windows one
# that reads that as the current drive's \mingw64\bin and finds nothing.
echo "== 4. an MSYS2 POSIX path from ldd resolves through cygpath"
if run_bundler bundle_win_dlls.py fbneo.exe msyspath "$W/msys"; then
    miss=""
    for f in SDL2.dll libpng16.dll; do
        [ -f "$W/msys/$f" ] || miss="$miss $f"
    done
    if [ -z "$miss" ]; then
        echo "  ok    /mingw64/bin/… translated: the closure is bundled ($(ls "$W/msys" | tr '\n' ' '))"
    else
        echo "  FAIL  the bundler succeeded but did not bundle:$miss"; fail=1
    fi
else
    echo "  FAIL  the bundler refused a path cygpath can translate:"; sed 's/^/        /' "$W/msys/out.txt" | tail -3; fail=1
fi
# and WITHOUT cygpath the same input must REFUSE, never quietly skip the DLL
make_stubs "$W/stub_msyspath" msyspath; rm -f "$W/stub_msyspath/cygpath"
rm -rf "$W/msys_nocyg"; mkdir -p "$W/msys_nocyg"
printf 'stub executable\n' > "$W/msys_nocyg/fbneo.exe"; chmod +x "$W/msys_nocyg/fbneo.exe"
if ( PATH="$W/stub_msyspath:$PATH" python3 "$TOOLS/bundle_win_dlls.py" "$W/msys_nocyg" "$W/msys_nocyg/fbneo.exe" ) > "$W/msys_nocyg/out.txt" 2>&1; then
    echo "  FAIL  with no cygpath an unopenable path was accepted — a bundle that is not self-contained"; fail=1
elif grep -q "REFUSING:.*does not exist" "$W/msys_nocyg/out.txt"; then
    echo "  ok    with no translator the same path REFUSES, naming the file ($(grep -o 'imports [^ ]*' "$W/msys_nocyg/out.txt" | head -1))"
else
    echo "  FAIL  it failed for another reason: $(tail -1 "$W/msys_nocyg/out.txt")"; fail=1
fi

# ---- must-fire controls ----------------------------------------------------
# (1) empty-closure is section 2, run above against $TOOLS: under the mode the
#     refusal is gone from the copy, section 2 reports SUCCESS-on-empty and the
#     gate fails there. Here it is only reported.
if run_bundler bundle_elf_libs.py fbneo silent "$W/ctl1" ; then
    vs_ctl_dead empty-closure "the linux bundler accepted an empty closure"; fail=1
else
    vs_ctl_fired empty-closure "both bundlers exit non-zero with 'REFUSING: the closure is EMPTY' (section 2)"
fi
# (2) unbundled-leftover: the stub readelf reports a NEEDED nobody bundles.
if run_bundler bundle_elf_libs.py fbneo leftover "$W/ctl2"; then
    vs_ctl_dead unbundled-leftover "a NEEDED library that is neither bundled nor a host library passed the artifact check"
    fail=1
elif grep -q 'LEFTOVER:.*libghost.so.9' "$W/ctl2/out.txt"; then
    vs_ctl_fired unbundled-leftover "$(grep -m1 'LEFTOVER:' "$W/ctl2/out.txt")"
else
    vs_ctl_dead unbundled-leftover "the bundler failed for another reason: $(tail -1 "$W/ctl2/out.txt")"
    fail=1
fi
# (3) msys-path-untranslated: section 4 above runs against $TOOLS, so under the
#     mode the copy's winpath() is a no-op and section 4's first half fails.
if run_bundler bundle_win_dlls.py fbneo.exe msyspath "$W/ctl3"; then
    vs_ctl_fired msys-path-untranslated "an MSYS path resolves only because winpath() translates it (section 4)"
else
    vs_ctl_dead msys-path-untranslated "the unmodified bundler could not resolve a translatable path" || true
    fail=1
fi

[ "$fail" = 0 ] && echo "PASS: test_bundle_parsers" || { echo "FAIL: test_bundle_parsers"; exit 1; }
