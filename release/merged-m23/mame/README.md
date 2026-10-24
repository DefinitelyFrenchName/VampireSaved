# VAMPIRE SAVED — merged-m23 (MAME package)

**What this is.** Vampire Savior (the arcade fighting game, 1997) with three
characters added who were never in it: **Donovan**, **Phobos** (called Huitzil in
the Western release) and **Pyron**. They come from two sister games Capcom built on
the same hardware. Nothing else is changed: every original character plays exactly
as before. When it runs, the character-select screen shows the mark **`M23`** in
the bottom-right corner, and the first screen reads **VAMPIRE SAVED**.

**This package contains NO ROM DATA and no copyrighted asset.** It carries a list of
*differences* that turn the game files you already own into the modified game. By
themselves they are not playable and contain nothing of Capcom's.

## Quick start

1. **Build the game file** from your own dumps: double-click `apply_release.html`
   and save the `vsavjw.zip` it gives you into a folder called `rompath` in this
   folder ("Build the romset" below).
2. **Play:**
   - **macOS, the first time:** open Terminal in this folder and run
     `sh PLAY.command`, then answer `y` when it asks to clear the quarantine flag
     ("Play on MAME" below says why). After that, double-clicking `PLAY.command` works.
   - **Linux:** `sh PLAY.command`.
   - **Windows:** double-click `PLAY.bat`.

## What you need

1. **Your own copies of the original arcade game files** (*ROM sets*, or *dumps*:
   ordinary `.zip` files). **We cannot give them to you**: they are Capcom's property.
   Put them, unmodified and with exactly these names, together in one folder:
   - `vsavj.zip` (Vampire Savior, Japan 970519)
   - `vsav.zip` (Vampire Savior, Europe 970519)
   - `vsav2.zip` (Vampire Savior 2, Japan 970913)
   - `qsound_hle.zip` (the QSound sound chip's own program). The build asks for it
     by default; see "The QSound program" below.

   Vampire Hunter 2 is not needed.
2. **A web browser, or Python 3** (3.8 or newer) for step 1. Both build exactly the
   same file. If you are not sure, use the browser.
3. **About 60 MB of disk space and ten minutes.**

## Build the romset (step 1)

The game file is `vsavjw.zip`. You build it from your own dumps, in one of two ways;
both give the same file.

**Option 1: In your browser.** Double-click `apply_release.html`. Choose your dump files (or
drag them onto the page), press **Build**, and save the `vsavjw.zip` it gives you
into a folder called `rompath` in this folder (make it if it is not there). The page runs entirely on your machine: it has no network code, your
dumps are not uploaded, and it works with the internet disconnected. If your browser
is too old, it says so; then use the command below.

**Option 2: With Python.** Open a terminal in this folder and run, with the folder that holds
your dumps in place of `/path/to/your/dumps`:

    python3 apply_release.py --romdir /path/to/your/dumps --out ./rompath

On Windows, type `py` instead of `python3`. To open a terminal in this folder on
macOS: open **Terminal** (Applications > Utilities), type `cd ` with the space, drag
this folder onto the window, and press Return. It prints a line per step and ends
with `OK:`.

Either way, every byte is checked against this release's fingerprints before
anything is written. A wrong, renamed or damaged dump is named, and nothing is
written.

`vsavjw.zip` is the **only** game file the emulator needs: everything it asks for is
inside it, copied from your own dumps. Do not put `vsav.zip`, `vsavj.zip` or
`qsound_hle.zip` beside it.

## Play on MAME (step 2)

**The launcher.** `PLAY.command` (macOS, Linux) and `PLAY.bat` (Windows) find the
emulator for your system under `emulator/bin/<os-arch>/`, check it is the prepared
one, put `vsavjw.zip` where it looks, and start the game. They look for `vsavjw.zip`
in `rompath/`, in this folder and in `roms/`, and take the newest.

- **macOS, the first time:** macOS blocks anything downloaded that Apple did not
  approve, and that includes `PLAY.command` itself, so double-clicking it the first
  time does not work. Open **Terminal** (Applications > Utilities), type `cd ` with
  the space, drag this folder onto the window, press Return, then run:

      sh PLAY.command

  It says macOS has quarantined the download and asks whether to clear the flag on
  this folder; answer `y`. That clears every file in the folder, so from then on
  double-clicking `PLAY.command` works.
- **Linux:** `sh PLAY.command` in a terminal opened in this folder.
- **Windows:** double-click `PLAY.bat`.

**By hand, or with the recipe package** (the launchers run only a prebuilt program,
so with an emulator you built yourself they stop and say so; the recipe package's
`EMULATOR.md` says how to build one): start the emulator with `-rompath` naming the folder that holds `vsavjw.zip`, for example `-rompath rompath` from this folder. The game's
name is `vsavjw`. `vsavjw.zip` is the only game file it needs.

**When it works,** the first screen reads **VAMPIRE SAVED** and the select screen
shows `M23` in the bottom-right corner, with Donovan, Phobos and Pyron
among everyone else.

## The QSound program — the one choice in the build

The arcade board's sound chip had a small program of its own, `dl-1425.bin`, which
comes from `qsound_hle.zip`.

- **Keep it (the default).** You need `qsound_hle.zip` among your dumps, and the game
  file then runs on every emulator. **MAME needs it**: it refuses the game file
  without it (`dl-1425.bin - NOT FOUND`).
- **Leave it out:** pick "Leave it out" in the browser page, or add
  `--no-qsound-bios` to the command. You then do not need `qsound_hle.zip`.
  **This is the choice for MiSTer**, where every CPS-2 game already needs your own
  `qsound.zip` in `games/mame/` and the core reads the program from there. FBNeo
  runs either file the same.

The build prints the key of the file it wrote; "Identify the build" lists both.

## Report a problem — and record it

Open an issue at https://github.com/DefinitelyFrenchName/VampireSaved/issues and say which package you used (`merged-m23-mame-<os-arch>`) and
the mark on the select screen (`M23`). If you can make it happen again, **record it**:
the project replays a recording frame for frame, which is how every reported problem
is reproduced and then tested for.

1. In this folder, next to `PLAY.bat` and `PLAY.command`, make two empty folders,
   `nvram_fresh` and `recordings`. `rompath/` must hold the `vsavjw.zip` you built.
2. Open a terminal in this folder and run the line for your system. Type it as it is:
   the folder names are real names, not placeholders to replace.
   - **Windows** (Command Prompt):

         emulator\bin\windows-x86_64\cps2.exe vsavjw -rompath rompath -nvram_directory nvram_fresh -input_directory recordings -record my_session.inp

     In PowerShell, put `.\` in front: `.\emulator\bin\windows-x86_64\cps2.exe …`
   - **macOS:**

         ./emulator/bin/macos-arm64/cps2 vsavjw -rompath rompath -nvram_directory nvram_fresh -input_directory recordings -record my_session.inp

   - **Linux:**

         ./emulator/bin/linux-x86_64/cps2 vsavjw -rompath rompath -nvram_directory nvram_fresh -input_directory recordings -record my_session.inp

3. MAME prints the four "megaman" errors and opens on the red box (see "If it does
   not work"): press any key. Play until the problem happens, then quit (Esc).
4. Then attach `recordings/my_session.inp` to the issue.

Start each recording with an **empty** `nvram_fresh` folder (empty it, or make a new
one): the game saves its settings there, and a recording replays exactly only from the
same starting state.

## If it does not work

- **macOS says "Not Opened — Apple could not verify…"**, with only *Done* and
  *Move to Bin*. macOS blocks programs that were not submitted to Apple, and a
  downloaded `PLAY.command` is one of them; nothing is wrong with the files.
  Right-click > Open does not get past it on current macOS. Run it from Terminal
  as in "Play on MAME" (`sh PLAY.command`, then `y`), or clear the flag yourself in a
  terminal opened in this folder: `xattr -dr com.apple.quarantine .`
  - **The longer way, without a terminal:** after a blocked attempt, open **System
    Settings > Privacy & Security** and click **Open Anyway** next to the blocked
    program. You have to do this for each blocked file separately: for this MAME, 2 files.
- **On Windows, double-clicking `cps2.exe` finds no game files ("NOT FOUND")** — it needs to be told
  where the game file is (`cps2.exe vsavjw -rompath rompath`). Double-click `PLAY.bat` instead.
- **"Unknown system: vsavjw" / "no such driver"** — this is not the prepared
  emulator, so it does not know this game. Use the one in this package, or build one
  from the recipe package. Renaming files never makes an ordinary emulator work: a
  renamed set sits on the QSound / CAPCOM screen forever.
- **Four "Driver is a clone of nonexistent driver megaman" errors at every start**,
  and **a red box "One or more ROMs/disk images for this system are incorrect…
  Press any key to continue"** — both are expected and harmless. This MAME is built
  with the CPS-2 games only, and MAME's own checksums can never match the files this
  build adds; your files were already checked by the build. Press any key and the game
  starts.
- **"reference dumps do not match the manifest"** — one of your dumps is not the
  exact version expected: another region, another revision, or modified. The message
  names the file. Nothing is written.
- **A character looks wrong, or the sound is missing** — almost always a dump of the
  right size with the wrong contents. Build the game file again: the check names the
  part.
- **Playing online** — both players need the same emulator and the same game file.
  Compare the keys under "Identify the build".

## Identify the build

- In the game: the mark `M23` at the bottom-right of the character-select screen.
- On disk: the game file's key is `67f12ab3` (`6e0f9030` built with
  `--no-qsound-bios`). `manifest.json` carries both, with every part's SHA-1.
  (The build this was packaged from is `f601342d`: the difference is the parts copied in
  from your own dumps.)

## What is in this package

- `PLAY.command` (macOS, Linux) and `PLAY.bat` (Windows) — start the game. They find
  the emulator for your system, check it is the prepared one, put `vsavjw.zip` where
  it looks, and start it; if something is missing, they name it.
- `apply_release.html` — step 1 in a browser. One plain file you can read.
- `apply_release.py` — step 1 with Python. A test checks on every build that it and
  the page produce the same file.
- `patches/` — 20 difference files, one per changed part of the game. Useless
  without your own dumps.
- `manifest.json` — the fingerprints everything is checked against.
- `emulator/bin/<os-arch>/` — the prepared MAME, and `BINARY.txt` with a fingerprint
  for every file. (The recipe package has `EMULATOR.md` and the patch instead.)

**Why an ordinary emulator will not work.** The three added characters need more
storage than a real CPS-2 board had, so this version runs on a slightly extended
board. A normal MAME knows only the original board: it refuses the file, or sits on the
startup screen forever. The MAME here is an ordinary MAME with one small published
change that teaches it the larger board.

## What is patched — for the curious

The finished `vsavjw.zip` has 20 parts rebuilt from the differences in
`patches/` and 12 copied untouched from your own dumps; 7 of those copies
are there so the file needs nothing beside it: `dl-1425.bin` from `qsound_hle.zip` (the optional one), and `vm3.11m`, `vm3.12m`, `vm3.14m`, `vm3.16m`, `vm3.18m`, `vm3.20m` from `vsav.zip`.

The difference files hold only what this project wrote: relocated program code, data
tables, the version lettering. Anything from the original games is "copy it from the
player's own file". Before a release is published, an automated check scans every
difference file for runs of original game data and refuses to ship if it finds any.
