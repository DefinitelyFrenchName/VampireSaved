# Building the release emulator binaries on the Windows machine

**Both tracks, one machine.** You will produce two sets of prebuilt
emulators — the Windows ones natively under MSYS2, the Linux ones under WSL2 —
and the project's own gate will decide whether each is shippable.

|  | where you build it | what it is filed as | who it is for |
|---|---|---|---|
| **Track W** | MSYS2 **MINGW64** shell | `windows-x86_64` | Windows players |
| **Track L** | WSL2 (Ubuntu) | `linux-x86_64` | Linux players |

Each track produces two binaries: a patched **FBNeo** and a patched **MAME**
(CPS-2 subtarget). Four builds in total.

> **Read this once before starting.** The Linux and Windows halves of the
> build tooling were written on the project's Mac, which has neither operating
> system, so **you are the first person to run them.** Everything that could be
> proven without those hosts has been (the parsers, the closure walk, the
> refusal to report success on an empty closure); what happens against real ELF
> and real PE files is what your session finds out. **Expect to fix something.**
> That is the honest state, not pessimism — and section 7 says what to send back
> so a fix is one round trip, not three.

---

## 0. What you need, and what you will never find in this repository

**You need, once:**

- the **three ROM dumps** — `vsavj.zip`, `vsav.zip`, `vsav2.zip`. These are
  yours; **no ROM data is ever in this repository or in any release**, and
  nothing in this bundle contains a single ROM byte. Copy them onto the machine
  by hand.
- about **15 GB** of disk and an hour or two of wall clock, most of it MAME
  compiling.

**You do NOT need:** the full build pipeline, a merged build, or the rest of
the test harness. Section 3 gets the romset the gate needs out of the published
release in about a minute, and that has been **measured** to produce a set
byte-identical to the frozen M18 build (program fingerprint `1d8bedc5`), with
the gate passing against it in full.

---

## 1. Get the two environments

**Track W — MSYS2.** Install from [msys2.org](https://www.msys2.org). When it is done,
open **"MSYS2 MINGW64"** from the Start menu — *not* "MSYS2 MSYS".

> This one detail matters more than any other on Windows. A binary built in the
> plain **MSYS** shell links the MSYS2 runtime and is a Cygwin-like executable
> that **will not run on a player's machine**. The preflight in section 2
> refuses to continue if you are in the wrong shell, so you cannot get this
> wrong silently.

```bash
pacman -Syu          # then re-open the window if it asks you to
pacman -S --needed git make patch rsync zip unzip perl coreutils \
    mingw-w64-x86_64-gcc mingw-w64-x86_64-binutils mingw-w64-x86_64-python \
    mingw-w64-x86_64-pkgconf mingw-w64-x86_64-SDL2 mingw-w64-x86_64-SDL2_image
```

**The SDL2 packages are FBNeo's, and MAME needs no SDL here at all** —
its Windows OSD is the native one (`emu/mame/makefile`, "specify OSD layer":
`TARGETOS=windows` selects `OSD=windows`, where Linux selects `sdl` and macOS
`sdl3`). An earlier version of this list asked for `mingw-w64-x86_64-SDL3` and
was wrong twice over: MSYS2 spells SDL3 lowercase (`SDL3` is `target not
found`, measured on a real host 2026-09-12) and nothing on this track needs
it. **SDL2 keeps its capitals** — lowercasing it to match anything fails the
same way.

**Track L — WSL2.** If WSL2 is not installed yet, `wsl --install` in
PowerShell; `docs/project/WSL2_SETUP.md` sections 0-2 cover it for someone who
has never used it. Then, inside Ubuntu:

```bash
sudo apt update && sudo apt install -y build-essential python3 git rsync \
    patch pkgconf zip unzip perl patchelf binutils coreutils \
    libsdl2-dev libsdl2-image-dev libsdl3-dev
```

MAME needs **no SDL3 here**: on Linux its OSD is `sdl` — SDL2, SDL2_ttf and
fontconfig — and `libfontconfig-dev` plus `libsdl2-ttf-dev` are the two this
list used to miss. SDL3 is the macOS OSD only (corrected 2026-09-12, measured
from the pinned source; this page previously sent you to build SDL3 from
source for nothing).

---

## 2. Clone, and ask the host whether it is ready

**Do this in each environment separately.** They are different machines as far
as the toolchain is concerned, and WSL2 must work inside its own Linux home
directory, never under `/mnt/c` (building across that bridge is dramatically
slower and has its own file-semantics surprises).

```bash
cd ~
git clone https://github.com/DefinitelyFrenchName/VampireSaved.git vampire-saved
cd vampire-saved
git submodule update --init --depth 1 emu/fbneo emu/mame
```

Keep the path free of spaces — MAME's build system cannot handle one.

**Where your Windows files are, and it differs between the two shells** (the
maintainer hit this on the first setup, 2026-09-12):

| shell | `C:\Users\You\roms` is | home is |
|---|---|---|
| MSYS2 MINGW64 | `/c/Users/You/roms` | `C:\msys64\home\<user>`, NOT your Windows profile |
| WSL2 Ubuntu | `/mnt/c/Users/You/roms` | the Linux home, a different filesystem |

`mount` prints the table on either, and `cygpath -u 'C:\path'` /
`cygpath -w /c/path` convert both ways in MSYS2 — ask the host rather than
trust this table. **You do not have to copy the dumps at all**: the applier
only READS them, so `ROMDIR` may point straight at the Windows folder. The
"never build under `/mnt/c`" rule above is about the TREE, which is written to
constantly; three zips read once cost nothing.

Then, with your dumps in place:

```bash
export ROMDIR=/c/Users/You/roms           # MSYS2; WSL2: /mnt/c/Users/You/roms
                                          # or copy them in: mkdir -p ~/roms &&
                                          # cp /c/Users/You/roms/*.zip ~/roms/
tools/preflight_release_build.sh
```

It builds nothing and writes nothing. It names the environment, the `os-arch`
your binaries will be filed under, and every missing tool with the exact
command that installs it. **Do not start a build until it says READY** — the
expensive failure is MAME dying six minutes in because pkg-config cannot see
SDL3, and that is one question asked up front.

---

## 3. Get the romset the gate boots (about a minute)

The gate does not just inspect the binaries: it **boots the real romset on
each one**, and the MAME leg reproduces a frozen expectation of the current
freeze. So it needs `vsavjw.zip`. Build it from your own dumps with the
published applier — pure Python, no build pipeline:

```bash
mkdir -p build/fromrelease/rompath
python3 release/merged-m18/fbneo/apply_release.py \
        --romdir "$ROMDIR" --out build/fromrelease/rompath
```

It must end with `every member verified`. It refuses to write anything at all
unless every member's checksum matches, so a wrong or damaged dump is caught
here rather than halfway through the gate.

`build/fromrelease` is where section 5 points the gate.

---

## 4. Build — one command per emulator

First, see what this host resolves. **This builds nothing:**

```bash
CHECK=1 tools/build_release_emulators.sh fbneo
```

Check the `os-arch` line reads `windows-x86_64` (Track W) or `linux-x86_64`
(Track L). If it is not what you expect, stop and say so: the gate looks for
that exact directory name, and a mismatch would make it **skip**, which reads
as "nothing to check" rather than "wrong name".

Then:

```bash
tools/build_release_emulators.sh fbneo     # minutes
tools/build_release_emulators.sh mame      # longer — this is the slow one
```

**Do FBNeo first.** It is the cheaper build and the likelier of the two to
work first time, so it tells you whether the environment is sound before you
spend the long one.

Each writes `release/emulators/<kind>/<os-arch>/` containing the executable,
the libraries it needs beside it, and a `BINARY.txt` record — a sha256 for
every file, the upstream pin, the driver-patch sha1, the recipe, the measured
minimum OS, and how to run it.

**On Linux, one thing is worth knowing while it runs:** the glibc floor of what
you produce is whatever the build host carries, and glibc is backward
compatible but never forward. A binary built on the newest Ubuntu refuses to
start on anything older. If you want broad compatibility, build Track L on the
oldest Ubuntu LTS you are willing to support; the record states what it
measured either way.

---

## 5. The gate — this is what decides whether they ship

```bash
ROMDIR=~/roms MERGED=build/fromrelease tests/test_release_binaries.sh
```

It checks, for this host's `os-arch`:

- **the record** — every file's sha256 matches `BINARY.txt`, every file is
  named, the key lines are present;
- **self-containment** — every library the loader actually resolves is beside
  the binary or a system path, and nothing is "not found". On Windows, every
  import resolves beside the `.exe` or to Windows itself. This is a *resolution*
  check through your host's own `ldd`, not a re-reading of what the bundler
  believed;
- **the signature**, where the platform has one. Windows has no equivalent of
  macOS's ad-hoc signing, so there the sha256 rows are the integrity and the
  gate says so rather than asserting a signature that cannot exist;
- **the profile is present and the test harness is absent** — the replay
  harness is a measuring instrument and must never ship;
- **a real boot of the romset on each binary** — FBNeo headless for 20 s (the
  profile line, 31 members loading, still running when killed), and MAME
  reproducing a frozen masked expectation of the current freeze, which is the
  strongest claim available: your shipped binary and the project's gate
  instrument traverse the same RAM.

`PASS: test_release_binaries (<os-arch>)` is the green light. Anything else,
send section 7's report.

---

## 6. Publish, or hand back

Either, from that machine (needs `gh` authenticated):

```bash
tools/upload_release_assets.sh freeze/merged-m18
```

Or simply zip `release/emulators/` and send it over — the record travels with
the files and is what makes a downloaded asset verifiable. There is no rush to
publish from the build host; the record is what matters.

---

## 7. If something goes wrong — what to send

One command collects everything useful and nothing private:

```bash
tools/collect_build_report.sh
```

It writes a single `build-report-<os-arch>-<date>.txt` holding the preflight
output, the tool versions, the `CHECK=1` plan, the tail of any build log, the
`BINARY.txt` records that exist, and the gate's output. **It contains no ROM
data** and no contents of your dumps — only names and whether checksums
matched.

Send that one file. It is usually enough to turn a failure into a one-line fix.

### The four things most likely to bite, and what each means

1. **`patchelf` missing** (Track L) — the Linux bundler refuses by name.
   `sudo apt install patchelf`.
2. **"REFUSING: the closure is EMPTY"** — both bundlers refuse rather than
   declare a binary self-contained when they find nothing to bundle. It means
   `ldd`/`readelf`/`objdump` printed something the parser did not recognise on
   your host. **This is the interesting failure**: capture the raw output of the
   command it names and send it — the fix is a line in the parser's fixtures,
   and your host is the only place that shape exists.
3. **MAME dies minutes in on `SDL3/SDL.h` not found** — pkg-config cannot see
   SDL3. The preflight checks exactly this; re-run it.
4. **The binary runs here but not on another machine** (Track L) — the Linux
   build deliberately leaves the GPU stack, the X11/Wayland and udev/dbus
   clients, ALSA/PulseAudio and glibc itself to the user's machine, because
   bundling any of them breaks the driver or the daemon protocol. If a *second*
   machine reports a missing library, that list is where the fix goes — and a
   second machine is the only instrument that can find it. Worth one test on a
   different box before publishing Track L.

### What a red gate means

A red gate is a question, not a verdict on your machine. The first question is
always which side rests on a measurement. Send the report rather than adjusting
anything to make it green: a frozen expectation edited to fit is how a baseline
quietly stops meaning anything.
