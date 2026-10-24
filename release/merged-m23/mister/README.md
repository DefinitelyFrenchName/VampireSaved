# VAMPIRE SAVED — merged-m23 (MiSTer package)

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

1. **Build the game file** from your own dumps, without the QSound BIOS member: in
   `apply_release.html` pick "Leave it out", or run the command with
   `--no-qsound-bios` ("Build the romset" below).
2. **Copy it and the core to your SD card** as "Play on MiSTer" below and `MISTER.md` say,
   and start "Vampire Saved - CPS-2 WIDE" from the Arcade menu.

## What you need

1. **Your own copies of the original arcade game files** (*ROM sets*, or *dumps*:
   ordinary `.zip` files). **We cannot give them to you**: they are Capcom's property.
   Put them, unmodified and with exactly these names, together in one folder:
   - `vsavj.zip` (Vampire Savior, Japan 970519)
   - `vsav.zip` (Vampire Savior, Europe 970519)
   - `vsav2.zip` (Vampire Savior 2, Japan 970913)
   - not `qsound_hle.zip`: on MiSTer you build without it (see "The QSound program"
     below), and the core takes that member from the `qsound.zip` your card already
     holds for every CPS-2 game.

   Vampire Hunter 2 is not needed.
2. **A web browser, or Python 3** (3.8 or newer) for step 1. Both build exactly the
   same file. If you are not sure, use the browser.
3. **About 60 MB of disk space and ten minutes.**

## Build the romset (step 1)

The game file is `vsavjw.zip`. You build it from your own dumps, in one of two ways;
both give the same file.

**Option 1: In your browser.** Double-click `apply_release.html`. Choose your dump files (or
drag them onto the page), press **Build**, and save the `vsavjw.zip` it gives you
anywhere you like; it goes on the SD card in step 2 ("Play on MiSTer"). The page runs entirely on your machine: it has no network code, your
dumps are not uploaded, and it works with the internet disconnected. If your browser
is too old, it says so; then use the command below.

**Option 2: With Python.** Open a terminal in this folder and run, with the folder that holds
your dumps in place of `/path/to/your/dumps`:

    python3 apply_release.py --romdir /path/to/your/dumps --out ./rompath --no-qsound-bios

On Windows, type `py` instead of `python3`. To open a terminal in this folder on
macOS: open **Terminal** (Applications > Utilities), type `cd ` with the space, drag
this folder onto the window, and press Return. It prints a line per step and ends
with `OK:`.

Either way, every byte is checked against this release's fingerprints before
anything is written. A wrong, renamed or damaged dump is named, and nothing is
written.

## Play on MiSTer (step 2)

1. Copy `jtcps2w.rbf` to `_Arcade/cores/` and the two `.mra` files to `_Arcade/`.
   Check the core's sha256 against `BITSTREAM.txt` after copying.
2. Put the `vsavjw.zip` you built (without the QSound program) in `games/mame/`.
   The core also reads `dl-1425.bin` from the `qsound.zip` your card already has there
   for every CPS-2 game.
3. Start "Vampire Saved - CPS-2 WIDE" from the Arcade menu.

`MISTER.md` has the full card layout: the `[STOCK CONTROL]` entry, what it needs
(your pristine `vsavj.zip` and `vsav.zip`), and why the ordinary `jtcps2.rbf` keeps
running stock Vampire Savior beside this one.

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

## Report a problem

Open an issue at https://github.com/DefinitelyFrenchName/VampireSaved/issues and say which package you used (`merged-m23-mister…`) and the
mark on the select screen (`M23`). If you can make it happen again, a **recording**
helps most: the project replays it frame for frame. Recordings are made with MAME, so
take the `merged-m23-mame-<os-arch>.zip` package (it builds the same `vsavjw.zip`) and
follow "Report a problem — and record it" in its README.

## If it does not work

- **The game is not in the Arcade menu, or the MiSTer reports a missing file** — a
  file is not where the MiSTer looks. "Play on MiSTer" and `MISTER.md` list each place.
- **"reference dumps do not match the manifest"** — one of your dumps is not the
  exact version expected: another region, another revision, or modified. The message
  names the file. Nothing is written.
- **A character looks wrong, or the sound is missing** — almost always a dump of the
  right size with the wrong contents. Build the game file again: the check names the
  part.

## Identify the build

- In the game: the mark `M23` at the bottom-right of the character-select screen.
- On disk: the game file's key is `67f12ab3` (`6e0f9030` built with
  `--no-qsound-bios`). `manifest.json` carries both, with every part's SHA-1.
  (The build this was packaged from is `f601342d`: the difference is the parts copied in
  from your own dumps.)

## What is in this package

- `apply_release.html` — step 1 in a browser. One plain file you can read.
- `apply_release.py` — step 1 with Python. A test checks on every build that it and
  the page produce the same file.
- `patches/` — 20 difference files, one per changed part of the game. Useless
  without your own dumps.
- `manifest.json` — the fingerprints everything is checked against.
- `jtcps2w.rbf`, `BITSTREAM.txt`, the two `.mra` files and `MISTER.md` — the core, its
  record, the menu entries, and where each file goes on the SD card.

**Why an ordinary CPS-2 core will not work.** The three added characters need more
storage than a real CPS-2 board had, so this version runs on a slightly extended
board. Jotego's own `jtcps2.rbf` knows only the original board. `jtcps2w.rbf` is that core
extended to the larger board, kept as a separate core so the ordinary one is
untouched.

## What is patched — for the curious

The finished `vsavjw.zip` has 20 parts rebuilt from the differences in
`patches/` and 12 copied untouched from your own dumps; 7 of those copies
are there so the file needs nothing beside it: `dl-1425.bin` from `qsound_hle.zip` (the optional one), and `vm3.11m`, `vm3.12m`, `vm3.14m`, `vm3.16m`, `vm3.18m`, `vm3.20m` from `vsav.zip`.

The difference files hold only what this project wrote: relocated program code, data
tables, the version lettering. Anything from the original games is "copy it from the
player's own file". Before a release is published, an automated check scans every
difference file for runs of original game data and refuses to ship if it finds any.
