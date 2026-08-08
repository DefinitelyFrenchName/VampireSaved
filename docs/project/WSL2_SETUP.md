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
sudo apt install -y build-essential python3 git rsync patch pkgconf \
                    libsdl2-dev libsdl2-image-dev perl
```

What each is for: `build-essential` = compiler + make; `python3` = build
scripts and all our analysis tools; `rsync` = the space-free build mirror;
`patch` = applying our emulator patches; `pkgconf` = **how MAME finds
SDL3** (without it the build dies minutes in on `'SDL3/SDL.h' file not
found`); the `libsdl2-*` and `perl` packages are FBNeo's requirements.

### SDL3 — check before assuming

MAME 0.288's frontend is SDL**3**, which is newer than SDL2 and may not be
packaged on older Ubuntu releases:

```bash
apt-cache policy libsdl3-dev
```

- If it shows a candidate version: `sudo apt install -y libsdl3-dev`
- If it says `Candidate: (none)`, build SDL3 from source:

```bash
sudo apt install -y cmake ninja-build
git clone --depth 1 https://github.com/libsdl-org/SDL.git ~/src-sdl3
cmake -S ~/src-sdl3 -B ~/src-sdl3/build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build ~/src-sdl3/build
sudo cmake --install ~/src-sdl3/build
sudo ldconfig
```

Either way, confirm pkg-config can see it — this is the exact check MAME
performs:

```bash
pkg-config --modversion sdl3      # must print a version, not an error
```

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
