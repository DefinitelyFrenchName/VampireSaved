# Known-good build environments — where a release binary was built AND passed its gate

**STATUS: INDEX of measured environments (opened 14z-152, 2026-09-13).** One entry
per host where `tools/build_release_emulators.sh` built a release emulator binary
AND `tests/test_release_binaries.sh` then PASSED on that same host. A host that
built but did not pass is not an entry; what stopped it is in "Conditions known
to break a build", with its measured cause.

## Why this page exists

The maintainer, 2026-09-13: *"most people would likely take a prebuilt fbneo or
mame, just create the vsavjw rom and be on their merry way. However, for both the
minority who like to build themselves and for us in the future, knowing in what
exact circumstances is the build known to be a success is the true minimum bar."*

A `BINARY.txt` record says WHAT was built: the upstream pin, the patch, the
recipe command, the host and its compiler. It did not say under which exact
conditions building worked, nor that the result then passed its gate. This page
is that answer. If your environment matches an entry, the recipe is known to
work there; if it does not, the entries are the closest measured starting point,
and the conditions table lists what has already gone wrong and why.

## How an entry is made

1. `tools/preflight_release_build.sh` says READY on the host.
2. `tools/build_release_emulators.sh fbneo|mame` builds. Its record carries the
   environment: `tree` (the commit built from), `jobs`, and one `env` line per
   prerequisite, read from the host's own package manager by
   `tests/lib/host_env.sh`.
3. `tests/test_release_binaries.sh` PASSES on the same host; keep its output.
4. `tools/record_build_environment.py <os-arch> <gate.log> <BINARY.txt>...`
   prints the entry. It REFUSES a log without the gate's PASS line, a record for
   another os-arch, and a record without `env` lines, so no entry rests on
   memory. Ground truth: `tests/test_build_environment_entry.sh`.

**The macOS entry below predates step 2** — its records were written before the
capture existed — so it was read on the same host two days after the build, and
says so in its `captured` row. The Windows and Linux entries come from the tool,
each from a rebuild with the capturing builder.

## Known-good environments

### macos-arm64 — FBNeo + MAME, built 2026-09-11, PUBLISHED

| | |
|---|---|
| host | macOS 26.6.2, arm64; Command Line Tools 27.0.0.0.1788430756; Apple clang 21.0.0 (clang-2100.3.34.2); GNU Make 3.81 |
| packages | Homebrew: `sdl2-compat` 2.32.70 (what `sdl2` names), `sdl3` 3.4.12, `sdl2_image` 2.8.12_1, `pkgconf` 3.0.5 |
| emulators | FBNeo `79188379cc84`, patch 0002 sha1 `17cd7516`; MAME `27a8d9e85b58` (mame0288), patch 0002 sha1 `1d13c9d8` |
| gate | PASS at 14z-149; PASS again 2026-09-13 (74 s, both must-fire controls fired) |
| published | `merged-m18-fbneo-macos-arm64.zip` and `merged-m18-mame-macos-arm64.zip` on `freeze/merged-m18` |
| captured | 2026-09-13, after the build: every Homebrew package listed was installed before it (the newest, `pkgconf`, on 2026-08-03), so these are the build-time versions |

### windows-x86_64 — FBNeo + MAME, built 2026-09-13

| | |
|---|---|
| host | Windows via MINGW64 (x86_64), cc.exe (Rev3, Built by MSYS2 project) 16.2.0 |
| system | Microsoft Windows [version 10.0.19045.7663]; MSYS2 runtime 3.6.10-da84778c.x86_64; MSYSTEM=MINGW64 |
| packages | pacman `coreutils` 8.32-5, pacman `diffutils` 3.12-1, pacman `git` 2.55.0-1, pacman `make` 4.4.1-3, pacman `mingw-w64-x86_64-SDL2` 2.32.10-1, pacman `mingw-w64-x86_64-SDL2_image` 2.8.12-1, pacman `mingw-w64-x86_64-binutils` 2.47-3, pacman `mingw-w64-x86_64-gcc` 16.2.0-3, pacman `mingw-w64-x86_64-pkgconf` 1~3.0.7-1, pacman `mingw-w64-x86_64-python` 3.14.7-1, pacman `mingw-w64-x86_64-sdl3` 3.4.16-1, pacman `patch` 2.7.6-3, pacman `perl` 5.42.3-1, pacman `rsync` 3.5.0-1, pacman `unzip` 6.0-3, pacman `zip` 3.0-5 |
| emulators | FBNeo `79188379cc84`, patch sha1 `17cd7516`; MAME `27a8d9e85b58`, patch sha1 `1d13c9d8` |
| built from | FBNeo tree `666b14d9e8dc`, jobs 24; MAME tree `666b14d9e8dc`, jobs 24 |
| gate | `PASS: test_release_binaries (windows-x86_64)` (test_release_binaries-windows-14z153.log) |
| published | `merged-m18-fbneo-windows-x86_64.zip` (55 files) and `merged-m18-mame-windows-x86_64.zip` (25 files) on `freeze/merged-m18`, 2026-09-13 — each downloaded back from GitHub and compared file for file |

Written by `tools/record_build_environment.py` from a REBUILD with the capturing
builder on the maintainer's box (MSYS2 MINGW64, driven over SSH, 14z-153), the
gate re-run on the rebuilt binaries with both must-fire controls firing. These
rebuilt binaries are the published ones. The first Windows build (2026-09-12)
predated the environment capture; the versions recorded here are identical to
the manual capture made of it on 2026-09-13. The upload ran from the Mac,
because `gh` is not installed on MSYS2 (ruled 2026-09-13).

### linux-x86_64 — FBNeo + MAME, built 2026-09-13

| | |
|---|---|
| host | Ubuntu 26.04 LTS (x86_64), cc (Ubuntu 15.2.0-16ubuntu1) 15.2.0 |
| system | Ubuntu 26.04 LTS (kernel 6.18.33.2-microsoft-standard-WSL2); ldd (Ubuntu GLIBC 2.43-2ubuntu2.4) 2.43 |
| packages | dpkg `binutils` 2.46-3ubuntu2, dpkg `build-essential` 12.12ubuntu2.26.04.2, dpkg `coreutils` 9.5-1ubuntu2+0.0.0~ubuntu25, dpkg `diffutils` 1:3.12-1ubuntu0.1, dpkg `gcc` 4:15.2.0-5ubuntu1, dpkg `git` 1:2.53.0-1ubuntu1, dpkg `libfontconfig-dev` 2.17.1-3ubuntu1, dpkg `libsdl2-dev` 2.32.10+dfsg-6, dpkg `libsdl2-image-dev` 2.8.8+dfsg-2, dpkg `libsdl2-ttf-dev` 2.24.0+dfsg-3, dpkg `make` 4.4.1-3, dpkg `patch` 2.8-2build1, dpkg `patchelf` 0.18.0-1.4build1, dpkg `perl` 5.40.1-7ubuntu0.3, dpkg `pkgconf` 2.5.1-4, dpkg `python3` 3.14.3-0ubuntu2, dpkg `qmake6` 6.10.2+dfsg-7, dpkg `rsync` 3.4.1+ds1-7ubuntu0.3, dpkg `unzip` 6.0-29ubuntu1, dpkg `zip` 3.0-15ubuntu3 |
| emulators | FBNeo `79188379cc84`, patch sha1 `17cd7516`; MAME `27a8d9e85b58`, patch sha1 `1d13c9d8` |
| built from | FBNeo tree `a145562c008e`, jobs 8; MAME tree `a145562c008e`, jobs 8 |
| gate | `PASS: test_release_binaries (linux-x86_64)` (test_release_binaries-linux-14z152-rebuilt.log) |

The first entry written by `tools/record_build_environment.py` itself (rebuilt
with the capturing builder on the maintainer's WSL2 box, gate re-run on the
rebuilt binaries, both must-fire controls firing). **A PROOF RUN, never
published:** its glibc floor is the build host's, 2.43, so it does not start
on Ubuntu 22.04 or 24.04; published Linux binaries are to come from the
dedicated server on an older LTS. The WSL2 build also needs a Windows-side WSL
window open for its whole run.

## Conditions known to break a build

| condition | what you see | cause | fix | paid |
|---|---|---|---|---|
| MSYS2's plain MSYS shell instead of MINGW64 | builds, then fails on a player's machine | the binary links the MSYS2 runtime | build from MINGW64; the preflight refuses otherwise | 14z-150 |
| a script assigns `OS` on Windows | the FBNeo link dies on `cannot find -lGL` | it overwrites Windows's exported `OS=Windows_NT`, which both makefiles key on | our scripts use `HOSTOS` | 2026-09-12 |
| MSYS2 without `diffutils` | the gate calls a run NONDETERMINISTIC | there is no `cmp` | `pacman -S diffutils` | 2026-09-13 |
| WSL2 with `JOBS` left at every core | MAME ten times slower, CPU pinned, swap in use | the VM gets all the cores but half the RAM | `JOBS=8`, or raise the memory in `.wslconfig` | 2026-09-12 |
| WSL2 with no WSL window open on the Windows side | a detached build vanishes | WSL shuts down when its last client closes | keep one WSL window open for the whole build | 2026-09-13 |
| Linux without `qmake6` | `char8_t` errors in `language.h`, minutes in | MAME's sdl config asks `qmake6` for an include path, and a bare `-I` swallows `-std=c++20` | `sudo apt install qmake6` (the tool only, no Qt linked) | 2026-09-13 |
| a Linux build host, for the self-containment check | a folder missing a bundled library still passes a path check | every bundled library also exists system-wide there | the Linux rule judges what the folder asks for against an external list | 2026-09-13 |

The paid-for detail of each is in `docs/platform/gotchas.md`.
