# Setting up the harness on Windows 10 via WSL2

Written for someone who has never used WSL2. Nothing here needs Linux
experience beyond copy-pasting commands, but it does explain what each step
is for, because a harness you cannot debug is not much use.

**What WSL2 actually is:** a real Linux kernel running in a lightweight VM
inside Windows, with its own filesystem, sharing your CPU/RAM/disk. You get
a Linux terminal. Windows keeps running normally alongside it. This is why
the Linux commands from earlier work here but not in PowerShell or CMD —
they need a Linux to run *in*.

**Why this and not native Windows:** our harness is POSIX shell scripts
(`tests/*.sh`, `tools/*.sh`) plus the **SDL** frontends of both emulators.
Native Windows would need MSYS2 for both emulators and a POSIX shell for
every gate. WSL2 gives us the Linux target directly — and everything you do
here transfers unchanged to the real Linux machine later, so the setup cost
is paid once, not twice.

**You do NOT need an X server or any GUI.** The harness runs fully
headless (`SDL_VIDEODRIVER=dummy`). Ignore any guide that tells you to
install VcXsrv or similar.

---

## 0. Check Windows can do this

WSL2 needs **Windows 10 version 2004 (build 19041) or newer**, and
**hardware virtualisation enabled in BIOS/UEFI**.

In PowerShell:

```powershell
winver                 # confirm version 2004 / build 19041 or higher
systeminfo | findstr /i "hyper-v virtualization"
```

If virtualisation is disabled, enable "Intel VT-x" / "AMD-V" (sometimes
"SVM Mode") in the BIOS. If Windows is older than 2004, update it first —
WSL2 genuinely will not work otherwise.

## 1. Install WSL2 + Ubuntu

In an **Administrator** PowerShell:

```powershell
wsl --install
```

That enables the required Windows features, installs WSL2 and Ubuntu, and
asks you to reboot. After the reboot, Ubuntu launches and asks for a
username and password — these are *Linux* credentials, unrelated to your
Windows login. Pick anything; you will need the password for `sudo`.

If `wsl --install` is not recognised (older Windows 10), do it manually:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
# reboot, then install the kernel update from
#   https://aka.ms/wsl2kernel
wsl --set-default-version 2
```
then install Ubuntu from the Microsoft Store.

Verify you are on version 2, not 1 — this matters for performance:

```powershell
wsl --list --verbose      # VERSION column must say 2
```

From here on, **every command goes in the Ubuntu terminal**, not
PowerShell.

## 2. THE ONE TRAP THAT MATTERS: where files live

WSL2 can see your Windows drives at `/mnt/c/...`. **Do not put anything
there.** Cross-filesystem access goes through a translation layer that is
dramatically slower, and we build ~900 MB of MAME sources.

Keep everything in the Linux home directory (`~`, i.e.
`/home/<youruser>`). That is the fast native ext4 filesystem.

To reach these files from Windows Explorer when you need to (e.g. to drop
the ROM zips in), type this in Explorer's address bar:

```
\\wsl$\Ubuntu\home\<youruser>
```

or, from the Ubuntu terminal, `explorer.exe .` opens the current directory
in Explorer.

## 3. Install the build prerequisites

```bash
sudo apt update
sudo apt install -y build-essential python3 git rsync patch pkgconf perl \
                    libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev libfontconfig-dev
```

What each is for: `build-essential` = compiler + make; `python3` = build
scripts and all our analysis tools; `rsync` = the space-free build mirror;
`patch` = applying our emulator patches; `pkgconf` = how both recipes find
their libraries. `libsdl2-dev` + `libsdl2-image-dev` + `perl` are FBNeo's;
`libsdl2-dev` + `libsdl2-ttf-dev` + `libfontconfig-dev` are MAME's.

### Which SDL MAME wants here — SDL2, and NOT SDL3

**Corrected 2026-09-12, measured from the pinned source after the
maintainer's Linux build died on a missing `fontconfig.pc`.** MAME picks a
different OSD per platform (`emu/mame/makefile`, "specify OSD layer"):

| `TARGETOS` | OSD | what it needs |
|---|---|---|
| `linux` | `sdl` | **SDL2**, **SDL2_ttf**, **fontconfig** |
| `windows` | `windows` | nothing from SDL — the native OSD |
| `macosx` | `sdl3` | SDL3 |

`scripts/src/osd/sdl.lua` is where the Linux OSD links `SDL2_ttf` and asks
pkg-config for `fontconfig`; miss either and the build dies well in, on a
link error or on `Package fontconfig was not found`.

**And NO Qt packages, despite what the build will ask for if you let it.**
Linux is the one platform where MAME defaults its Qt5 debugger ON
(`scripts/src/osd/modules.lua`), so a plain build stops on a missing `moc`
and the obvious fix is to `apt install qtbase5-dev`. Do not: it would LINK
Qt5 into a binary we then have to ship, tens of megabytes of GUI for a
debugger this project never opens — every gate drives `-debug -debugger none`
and Lua. `tools/setup_mame.sh` passes `USE_QTDEBUG=0` on Linux, which is
already the default on macOS and Windows, so the three binaries stay the same
instrument. Measured 2026-09-12, the first Linux build.

**This page used to send you to build SDL3 from source when Ubuntu had no
`libsdl3-dev`.** That was the macOS requirement written down as everyone's:
on Linux it is not needed at all, and the detour was pure cost. Confirm what
the build will actually look for:

```bash
pkg-config --modversion fontconfig   # must print a version, not an error
sdl2-config --version
```

## 3b. WSL2 gives the VM HALF your RAM, and the build asks for all your cores

**Measured 2026-09-12, the first Linux track:** FBNeo built in similar time on
MSYS2 and WSL2; MAME under WSL2 was still running after roughly TEN TIMES the
native Windows time on a Ryzen 3900X, with the CPU pinned. A pinned CPU reads
as "working hard" and is also what thrashing looks like.

The arithmetic, from Microsoft's documented `.wslconfig` defaults:

| setting | default |
|---|---|
| `memory` | 50% of total memory on Windows |
| `processors` | the same number of logical processors on Windows |
| `swap` | 25% of memory size, rounded up |

So a 32 GB / 24-thread host gives the VM **24 processors and 16 GB**. Our
builders default to `-j$(nproc)` = 24 parallel compilers, and MAME's larger
translation units are not small. Native Windows runs the same 24 jobs against
the whole 32 GB; WSL2 runs them against half.

**Two levers, either one enough:**

```bash
JOBS=8 tools/build_release_emulators.sh mame     # fewer, fatter jobs
```

(`MAME_JOBS=8` works too since 2026-09-12; before that this entry point
overrode it with `nproc` and the flag did nothing — the exact spelling this
page recommended.)

```ini
# %UserProfile%\.wslconfig   — then `wsl --shutdown` and reopen
[wsl2]
memory=24GB
swap=8GB
```

`tools/preflight_release_build.sh` now prints the GB-per-job this host will
run at and says so when it is under about 1.2 GB.

**How to tell a slow build from a thrashing one, while it runs:**

```bash
vmstat 1 5      # the si/so columns: swap IN and OUT, in KB/s
free -h         # is the Swap line filling up?
cat /proc/pressure/memory
```

`vmstat` is the unambiguous one: sustained non-zero `si`/`so` means the
machine is moving pages instead of compiling, and a compile that swaps is
the 10x. The pressure file needs reading correctly — `avg10`, `avg60` and
`avg300` are **time windows**, and each number is a **percentage of that
window spent stalled**, not a count:

```
some avg10=31.55 avg60=28.12 avg300=19.03 total=...
full avg10=18.21 avg60=15.44 avg300=10.87 total=...
```

`some` = at least one task was waiting on memory; `full` = EVERY task was,
so nothing useful happened at all. A few percent of `some` under load is
ordinary. `full` in double digits is a machine that is thrashing, and that
is the reading that matches a 10x wall clock. (If the file does not exist,
this kernel was built without pressure accounting — use `vmstat`.)

## 4. Get the repository

Clone to a path with **no spaces** (the Linux home directory has none,
which conveniently sidesteps a MAME build-system limitation documented in
`docs/GOTCHAS.md`):

```bash
cd ~
git clone <your-repo-url> vampire-saved
cd vampire-saved
git submodule update --init --depth 1 emu/fbneo emu/mame
```

## 5. Put the reference ROM sets in place

**The repository never contains ROM content** (CLAUDE.md rule 7), so these
have to be copied across by hand. You need the same six zips the Mac uses:
`vsavj.zip`, `vsav.zip`, `vsav2.zip`, `vhunt2.zip`, `vhunt2r1.zip`,
`qsound_hle.zip`.

Copy them onto the Windows machine however you like, then from Ubuntu:

```bash
mkdir -p ~/roms
cp /mnt/c/Users/<WindowsUser>/Downloads/*.zip ~/roms/     # one-time copy is fine
export ROMDIR=~/roms
```

Copying *through* `/mnt/c` once is fine — it is only the build that must
avoid it.

Now verify them. Do not skip this; every later result depends on these
bytes being exactly right:

```bash
python3 tools/audit_roms.py "$ROMDIR"
```

It must end with `verified 76 members against checksums.txt: all match`.
If it does not, stop and fix the ROM set — nothing downstream is
trustworthy otherwise.

Keep `ROMDIR` play-free: never point an emulator at it directly, or it
grows `cfg/`/`nvram/` directories.

To avoid re-exporting every session, append to `~/.bashrc`:

```bash
echo 'export ROMDIR=~/roms' >> ~/.bashrc
```

## 6. Build the emulators

```bash
cd ~/vampire-saved

# MAME: reference (unpatched) binary, then the CPS-2 WIDE one.
WIDE=0 tools/setup_mame.sh        # -> ~/.cache/vampire-saved/mame-ref/cps2
tools/setup_mame.sh               # -> ~/.cache/vampire-saved/mame/cps2

# FBNeo: reference binary, then the WIDE one.
WIDE=0 tools/setup_fbneo.sh && cp emu/fbneo/fbneo ~/fbneo_ref
tools/setup_fbneo.sh
```

Expect the first MAME build to take a while — it is a filtered CPS-2-only
build, so minutes rather than hours, but the exact time depends on your
core count. `setup_mame.sh` prints `verified: binary carries the vsavjw
driver` when the WIDE build is genuinely patched; if that line is missing,
something went wrong and the script will say so rather than hand you a
stock binary.

## 7. THE ACCEPTANCE TEST

This is the step that decides whether the machine can be trusted:

```bash
ROMDIR=~/roms tests/test_mame_parity.sh
```

It runs the whole frozen oracle corpus and must end with:

```
PASS: MAME parity. ... 62/62
```

**What green means:** this machine reproduces every frozen expectation
bit-for-bit, so every result in `tests/expected/` transfers unchanged and
you can work here exactly as on the Mac.

**What red means:** STOP, and do not re-freeze the expectations to make it
green — that would silently redefine the baseline the project's superset
invariant rests on. Report the failing replay and its first divergent
frame. A genuine cross-platform emulation difference would be a real and
interesting finding; a broken build is more likely, and the two are
distinguishable from the log.

Then the rest:

```bash
ROMDIR=~/roms tests/test_input_integrity.sh
ROMDIR=~/roms tests/test_mame_wide.sh
ROMDIR=~/roms FBNEO_REF=~/fbneo_ref tests/test_wide_profile.sh
```

(`test_mame_wide.sh` and `test_wide_profile.sh` need a WIDE romset built
first — see the CPS-2 WIDE section of `HANDOFF.md`.)

## 8. Day-to-day notes

- **Long runs**: they keep going as long as the Ubuntu terminal is open.
  Closing the window is fine if you started the job with `nohup ... &`;
  `wsl --shutdown` in PowerShell kills everything, so avoid it mid-run.
- **CPU/RAM limits**: WSL2 defaults to a generous share of the host. If you
  want to cap it so Windows stays responsive, create
  `C:\Users\<WindowsUser>\.wslconfig`:
  ```ini
  [wsl2]
  memory=8GB
  processors=4
  ```
  then `wsl --shutdown` to apply. Do not set `processors=1` — builds and
  the longer gates will crawl.
- **Disk**: budget ~5 GB (MAME source ~900 MB, plus its build tree twice
  over for the reference and WIDE mirrors).
- **No GUI required.** `tools/run_mame.sh` exports
  `SDL_VIDEODRIVER=dummy`, so nothing tries to open a window. If FBNeo ever
  complains about video initialisation, set the same variable for it.
- **Editing from Windows** is fine via `\\wsl$\Ubuntu\...`, or VS Code with
  the WSL extension, which is the smoothest option.

## 9. When the Linux machine arrives

Everything above transfers as-is — that was the point of choosing WSL2
over native Windows. Sections 3 through 7 are the entire Linux setup, minus
the WSL-specific parts (sections 0-2) and the `/mnt/c` caveat. Run the same
acceptance test there.

## 10. BUILD THE RELEASE BINARIES FOR THIS OS — one command per emulator

Written 14z-150, and **untested on any Linux or Windows host**: the tools
below were written on the project's Mac, which has neither. The parsers and
the closure logic they share are proven by `tests/test_bundle_parsers.sh`;
what happens on real ELF and real PE files is what THIS machine's session
finds out. Expect to fix something, and record what you fix.

Releases ship **the recipe AND a prebuilt binary, each user free to choose**
(maintainer-ruled 2026-09-11). macOS is built on the Mac; this section is how
the Linux and Windows binaries get made, on the machine that has that OS.

**Prerequisites beyond sections 3-6.** On Linux/WSL2 one extra package:

```bash
sudo apt install -y patchelf zip     # patchelf rewrites RUNPATH; zip is for the upload step
```

On Windows, work in an **MSYS2 MINGW64** shell (not the plain MSYS one). The
package list is `WINDOWS_BUILD.md` section 2 and is NOT copied here — two
copies drift, and this one had already lost `sdl3` (MAME's frontend), which
would have died minutes into its build on a pkg-config miss. Note when you
read it that **MSYS2 spells SDL3 lowercase and SDL2 capitalised**
(`mingw-w64-x86_64-sdl3`, `mingw-w64-x86_64-SDL2`); the capitalised SDL3 is
`target not found`, measured on a real host 2026-09-12.

**First, see what this host resolves — it builds nothing:**

```bash
CHECK=1 tools/build_release_emulators.sh fbneo
```

It prints the os-arch name, the bundler it will use, the executable name and
the output directory. If the os-arch is not what you expect, stop there: the
gate looks for that exact directory and would otherwise SKIP, which reads as
"nothing to check" rather than "wrong name".

**Then the two builds, one command each** (FBNeo minutes, MAME longer):

```bash
tools/build_release_emulators.sh fbneo
tools/build_release_emulators.sh mame
```

Each writes `release/emulators/<kind>/<os-arch>/` with the binary, its
bundled libraries and a `BINARY.txt` record (sha256 per file, the upstream
pin, the driver-patch sha1, the recipe, the measured minimum OS, how to run).

**Then the gate — this is what decides whether the binaries are shippable:**

```bash
ROMDIR=~/roms tests/test_release_binaries.sh
```

It checks the record, self-containment (on Linux: every library the loader
resolves is beside the binary or a system path, nothing "not found"; on
Windows: every import resolves beside the .exe or to Windows itself), the
profile, the absence of the replay harness, and it BOOTS the merged romset on
each binary — MAME reproducing a frozen masked expectation, so the shipped
binary is proven to be the same instrument the project's gates ran.

It needs a merged build to boot: either build one (`tools/build_merged.sh`,
HANDOFF "How to build") or pass `MERGED=<dir>` for one you have.

**Then either hand the directories back, or publish from here:**

```bash
tools/upload_release_assets.sh freeze/merged-m18        # needs `gh` authenticated
```

Or copy `release/emulators/<kind>/<os-arch>/` to the Mac and let that host
upload. Either way the record travels with the files — it is what makes a
downloaded asset verifiable.

### What to expect to go wrong the first time

- **`patchelf` missing** — the Linux bundler refuses by name; install it.
- **An empty closure** — both bundlers REFUSE rather than declare the binary
  self-contained. That means `ldd`/`readelf`/`objdump` printed something the
  parser did not recognise: capture the raw output and add its shape to
  `tests/test_bundle_parsers.sh`'s fixtures, which is where a parser shape is
  allowed to be learned.
- **A library that should not have been bundled.** Linux deliberately leaves
  the GPU stack (libGL/libEGL/libdrm), the X11/Wayland and udev/dbus clients,
  ALSA/PulseAudio and glibc itself to the user's machine — bundling any of
  them breaks the driver or the daemon protocol. If the binary fails on a
  SECOND machine with a missing library, the fix is a line in
  `tools/bundle_elf_libs.py`'s `SYSTEM_STEMS`, and the second machine is the
  only instrument that can find it.
- **The glibc floor is the build host's.** Building on the newest Ubuntu
  makes a binary that refuses to start on anything older. Build on the oldest
  LTS you are willing to support; the record states what it measured.
