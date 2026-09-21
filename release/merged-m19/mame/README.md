# VAMPIRE SAVED — merged-m19

**What this is.** Vampire Savior (the arcade fighting game, 1997) with three
characters added who were never in it: **Donovan**, **Phobos** (called Huitzil in
the Western release) and **Pyron**. They come from two sister games Capcom built
on the same hardware. Nothing else is changed — every original character plays
exactly as before. Once it is running, the character-select screen shows the mark
`M19` in the bottom-right corner, which is how you can tell you
are playing this and not the original.

**What you need before you start.** Three things, and the first one is the one we
cannot help with:

1. **Your own copies of the original arcade game files.** These are the contents
   of an arcade machine's chips, usually called *ROM sets* or *dumps*; they are
   ordinary `.zip` files. **We cannot give them to you** — they are Capcom's
   property, and this package deliberately contains none of them. You need
   `vsavj.zip`, `vsav.zip` and `vsav2.zip`, unmodified, with exactly those names,
   together in one folder. (A fourth, `qsound_hle.zip`, only for MAME — see
   "One optional member" below.)
2. **A way to run step 1 — and you almost certainly already have one.** Either
   **a web browser** (double-click `apply_release.html`, in this folder: no
   install, no terminal, and it works with the internet disconnected), or
   **Python 3**, a free programming language macOS and Linux already include and
   Windows offers in its store. Both produce exactly the same file. If you are
   not sure which you want, use the browser.
3. **Room and time**: about 60 MB of free disk space for the package and the
   file you build, and ten minutes. The build briefly uses around 150 MB of
   memory in Python, or around 300 MB in a browser tab — either way, less than
   any machine made this century has.

**What you are going to do — three steps, in this order:**

> **1. Build the game file.** One command turns *your* files into a new file,
> `vsavjw.zip`. That file is the modified game.
> **Double-click `apply_release.html`** and your browser does it, or run one
> command with Python — whichever you prefer.
> **2. Get the emulator** — the program that pretends to be the arcade machine.
> This package already contains one, prepared for this game. **An ordinary
> emulator you may already own will not work**; the reason is below.
> **3. Put them together and play.** On **macOS**, double-click
> **`PLAY.command`** and it does steps 2 and 3 for you. On Linux, run
> `sh PLAY.command`. On **Windows there is no launcher yet** — follow "Play on…"
> below by hand; it is four short steps.

**THIS PACKAGE CONTAINS NO ROM DATA AND NO COPYRIGHTED ASSET, EVER.** What it
carries instead is a list of *differences* — "take these bytes from the file you
already own, change these ones". Applied to your files they produce the modified
game; by themselves they are not playable and contain nothing of Capcom's. Every
byte produced is checked against an expected fingerprint before anything is
written, so a wrong, renamed or damaged file is reported by name instead of being
silently used.

**Why an ordinary emulator will not work.** The three added characters need more
storage than a real CPS-2 arcade board had, so this version runs on a slightly
extended board. A normal emulator knows only the original board: it will refuse
the file, or sit on the startup screen forever. The emulator here is an ordinary
FBNeo or MAME with one small published change that teaches it the larger board —
that is the only difference, and you can read the change if you want to.

## The deliverables — what to download, and what each is for
Everything ships as ASSETS of the GitHub release on tag `freeze/merged-m19`:
https://github.com/DefinitelyFrenchName/VampireSaved/releases/tag/freeze/merged-m19

**TAKE EXACTLY ONE.** Every asset below is complete on its own: the README,
the romset patch set, the applier, and ONE way to get the emulator or core.
There is nothing to combine and nothing to download twice.

| asset | what it is | who needs it |
|---|---|---|
| `merged-m19-fbneo-<os-arch>.zip` | the FBNeo package for that OS, **ready to play**: this README, the romset patch set + applier, and a prebuilt patched FBNeo with its `BINARY.txt` of sha256s. No build step, nothing to patch (available: macos-arm64, windows-x86_64) | FBNeo players on a listed OS |
| `merged-m19-fbneo-recipe.zip` | the same FBNeo package for **any** OS, carrying the driver patch + build recipe (`EMULATOR.md`) instead of a binary: you build the emulator once | FBNeo players on any other OS, or anyone who prefers to build |
| `merged-m19-mame-<os-arch>.zip` | the MAME package for that OS, ready to play: the same romset patch set + applier, and a prebuilt patched MAME (CPS-2 subtarget) with its `BINARY.txt` (available: macos-arm64, windows-x86_64) | MAME players on a listed OS |
| `merged-m19-mame-recipe.zip` | the same MAME package for any OS, with the driver patch + `EMULATOR.md` instead of a binary | MAME players on any other OS, or anyone who prefers to build |
| `merged-m19-mister.zip` | the MiSTer package: the same romset patch set + applier, the `jtcps2w.rbf` bitstream + its record (`BITSTREAM.txt`), the two `.mra` files, `MISTER.md` | MiSTer owners |
| "Source code (zip / tar.gz)" | added by GitHub to every release: the whole project repository at the tag — development tooling, logs and all. **NOT needed to play**; nothing above requires it | nobody, unless you want to audit or rebuild the project |

A prebuilt package deliberately carries NO emulator patch and no build
recipe: your binary already contains them, and a patch you cannot use is a
patch you might try to apply. If you want to read or rebuild what your binary
contains, the `-recipe` package of the same platform is where the patch
lives, and your `BINARY.txt` names its sha1.

Every package rebuilds the SAME `vsavjw.zip` from your own dumps (the three
copies of the patch set are byte-identical, and a gate asserts it).
**You are reading the MAME package.** In order: build the romset (below),
get the emulator or core ("Play on MAME" at the end), play.

## What is in this package
- `PLAY.command` — **on macOS, double-click this to play** once you have done
  step 1 (on Linux, `sh PLAY.command`; **not yet available for Windows**). It
  finds the right emulator for your machine, checks it really is the prepared
  one, puts the game file where the emulator will look, and starts it. If
  anything is missing it tells you which thing and what to do about it.
- `apply_release.html` — **step 1 in your browser.** Double-click it, choose your
  `.zip` dumps, press the button, save the file it gives you. Nothing is
  installed and nothing is uploaded: the page has no network code in it at all,
  and it works with the internet switched off. Open it and read it if you like —
  it is one plain file.
- `apply_release.py` — step 1 on the command line instead. Needs Python 3 and
  nothing else. It and the page produce the same romset, member for member, and
  a test asserts that on every build.
- `patches/` — 20 files of differences, one for each part of the game that
  changed. Not readable, not playable, and no use without your own game files.
- `manifest.json` — the list of expected fingerprints the applier checks
  everything against. You never edit this.
- this README, plus notes for your platform beside it

## What you need
- **Python 3** (3.8 or newer). No other tool: the applier decodes the
  patches itself.
- **The reference dumps, unmodified, with these exact names** in one
  directory: `vsavj.zip` (Vampire Savior, Japan 970519), `vsav.zip` (Europe
  970519), `vsav2.zip` (Vampire Savior 2, Japan 970913) — and `qsound_hle.zip`
  (the QSound BIOS set) UNLESS you pass `--no-qsound-bios`, for which see
  "One optional member" below. Vampire Hunter 2 is
  NOT needed (it is the project's verification oracle, not a source of
  anything in the set). The applier checks every member's SHA-1
  against the manifest before doing anything, so a wrong, renamed or
  modified dump is reported by name, never silently patched over.

## Build the romset

"Romset" is just the name for the game file the emulator loads. There are two
ways to make yours and they produce the same file; take whichever suits you.

### The easy way: your browser

**Double-click `apply_release.html`.** It opens as an ordinary web page. It lists
the dump files it needs, you choose them (or drag them onto it), you press
**Build**, and it hands you `vsavjw.zip` to save. It checks every byte against the
same fingerprints the command below does, and refuses to give you anything at all
if something does not match.

It runs entirely inside your browser, on your machine. Your dumps are not
uploaded — there is no code in that page capable of sending them anywhere, which
you can check for yourself, and it works with the internet disconnected.

*If your browser is too old it will say so plainly, in which case use the command
line below.*

### The other way: one command

To do the same thing with Python,
open a terminal, go to this folder, and run the line below — replacing
`/path/to/your/dumps` with the folder that holds your `vsavj.zip`, `vsav.zip`
and `vsav2.zip`:

    python3 apply_release.py --romdir /path/to/your/dumps --out ./rompath

If you have never used a terminal: on macOS open **Terminal** from
Applications > Utilities, type `cd ` (with the space), drag this folder onto the
window, and press Return — you are now "in" this folder. On Windows use
**PowerShell** the same way. It prints a line per step and finishes with `OK:`.

`./rompath/` then holds `vsavjw.zip`, and that is **the only file you place** —
it is a STANDALONE set: every member the emulator asks for is inside it,
including the ones normally resolved from the parent `vsav.zip` and MAME's
QSound BIOS, each copied pristine from your own dumps and SHA-1 verified. You
do not put `vsav.zip`, `vsavj.zip` or `qsound_hle.zip` in the emulator's rom
directory. The applier refuses to write if any member's SHA-1 does not match
the manifest. One member is optional — see below if you are on MiSTer.

## Play on MAME
You need the prepared emulator, and then the game file next to it.

1. **The emulator.** You already have it, or you build it once — whichever package
   you downloaded:
   - `merged-m19-mame-<os-arch>.zip` (built for: macos-arm64, windows-x86_64): the emulator is in this package
     under `emulator/bin/<os-arch>/`, where `<os-arch>` names your system —
     `macos-arm64` is an Apple-Silicon Mac, `windows-x86_64` an ordinary 64-bit
     Windows PC. `BINARY.txt` beside it lists a fingerprint for every file so you
     can confirm nothing was altered in transit. Nothing to build or patch.
   - `merged-m19-mame-recipe.zip`: no ready-made program, but the one small
     change (`emulator/0002-cps2-wide-v1.patch`) and step-by-step build commands
     in `EMULATOR.md`. Use this if your system is not listed above, or if you
     would rather build it yourself than trust a binary.
   Both routes give the same program.
2. **The easy way — macOS: double-click `PLAY.command`** (Linux:
   `sh PLAY.command`; not yet available on Windows). It picks the right program
   for your machine, checks it is the prepared one and not an ordinary copy,
   handles macOS's "downloaded from the internet" block, puts your `vsavjw.zip`
   where this emulator actually looks for it, and starts the game. If anything is
   missing it names it. Skip to step 4.
3. **By hand.** Put the `vsavjw.zip` you built in step 1 anywhere you like, and tell the emulator where by starting it with `-rompath "/that/folder"`.
   It is the **only** file you put there — not `vsav.zip`, not `vsavj.zip`, not
   the sound file. Everything the emulator needs is already inside it, as long as you built it the normal way (without `--no-qsound-bios`, which is for MiSTer and which MAME will refuse).
4. Start it. The emulator calls this game `vsavjw`. When it works, the first
   screen reads **VAMPIRE SAVED** and the character-select screen shows
   **M19** in the bottom-right
   corner. Donovan, Phobos and Pyron are on the select screen with everyone else.

## One optional member — the sound chip's own program

The arcade board's sound hardware had a small program of its own, in a file
called `dl-1425.bin`. It is the only part of the set you get a choice about,
because different emulators want it in different places.

- **Keep it (the default).** The romset is then self-sufficient on every
  emulator, MAME included. You need `qsound_hle.zip` among your dumps.
- **Leave it out:** in the browser page, pick "Leave it out" in step 3; on the
  command line, `python3 apply_release.py --romdir … --out … --no-qsound-bios`.
  You then do not need `qsound_hle.zip` at all.
  - **On MiSTer this is the one to pick.** Any CPS emulation on MiSTer already
    requires your own `qsound.zip` in the `games/mame` folder, so there is no
    reason to put a second copy inside the Vampire Saved romset. (Measured
    2026-09-20: all 31 parts still resolve — 30 from `vsavjw.zip` and the sound
    program from that `qsound.zip`.)
  - **FBNeo** runs the smaller set identically: its descriptor does not list the
    member; zero `(not found)`, same RAM and same framebuffer over 12,120 frames.
  - **MAME refuses the smaller set** (`dl-1425.bin - NOT FOUND`), so keep the
    member if MAME is your emulator.

Either way the applier prints the set key it wrote and checks it against this
release's own declaration, so you can tell at a glance which variant you hold —
and netplay peers must hold the same one.

## Identify the build
- In game: the mark `M19` at the bottom-right of the
  character-select screen, and the boot name screen reads VAMPIRE SAVED.
- On disk: whole-set key `923c1e7a` — the set the applier writes by default
  (`19ca6f3f` with `--no-qsound-bios`), which `manifest.json` carries as
  `applied_set_key` / `applied_set_key_no_qsound_bios` with every member's SHA-1.
  (The build this was packaged from is `61e9815a`; they differ by the standalone
  completion above, which is pristine content from your dumps.)

## If it does not work
Almost every first-time problem is one of these five.

- **macOS says the emulator "Not Opened — Apple could not verify…"** and offers
  only *Done* and *Move to Bin*. macOS is refusing to run a program that was not
  submitted to Apple for approval; nothing is wrong with the file. **Right-clicking
  and choosing Open does NOT get past it** on current macOS. Two things do:
  - **The one-step way (recommended).** On macOS, double-click `PLAY.command`; it
    offers to clear the "downloaded from the internet" mark for the whole folder at
    once and then starts the game. By hand, the same thing is one line in a terminal
    opened in this folder: `xattr -dr com.apple.quarantine .`
  - **Without a terminal at all.** After a blocked attempt, open **System Settings >
    Privacy & Security**, scroll to the message about the blocked program, and click
    **Open Anyway**. This works (confirmed 2026-09-20) but you must do it **for each
    blocked file separately** — and there are more than one, because the program
    carries its own copies of the libraries it needs. For MAME that is **2** files;
    **for FBNeo it is 24**, so on FBNeo prefer the one-step way above.
- **"Unknown system: vsavjw" / "no such driver"** — the emulator is not the
  prepared one, so it does not know this game. Use the emulator in this package,
  or build one with the recipe in `EMULATOR.md`. Your normal emulator cannot be
  made to work by renaming anything.
- **The game sits on the QSound / CAPCOM legal screen and never reaches the
  title** — you renamed the set to force it into an unpatched emulator. The
  stock 4 MB driver never loads the program extension, the sound driver or
  the QSound extension, so the boot handshake never completes (measured
  2026-09-11: no crash, no gameplay, the legal screen forever). It needs the
  patched emulator; renaming is never the fix.
- **"reference dumps do not match the manifest"** — one of your original game
  files is not the exact version expected: a different region, a different
  revision, or altered at some point. The message names the file and the part of
  it that differs. Nothing is written when this happens.
- **The game runs but a character looks wrong, or the sound is missing** — almost
  always a game file that is the right size but the wrong contents. Re-run the
  build command; it checks every part and will say which one.
- **Playing online against someone** — both of you need the same emulator AND the
  same game file. Compare the key printed under "Identify the build": if they do
  not match, you are not running the same thing.

## What is patched — for the curious, not needed to play
The finished `vsavjw.zip` has 20 parts rebuilt from the differences in
`patches/` and 12 copied across from your own files untouched. Of those
copies, 7 are there so the result needs no other file beside it:
dl-1425.bin <- qsound_hle.zip (optional), vm3.11m <- vsav.zip, vm3.12m <- vsav.zip, vm3.14m <- vsav.zip, vm3.16m <- vsav.zip, vm3.18m <- vsav.zip, vm3.20m <- vsav.zip.

The difference files describe only what this project itself wrote — relocated
program code, data tables, the version lettering. Anything that came from the
original games is expressed as "copy it from the player's own file" rather than
included, which is what keeps this package free of Capcom's content. Before any
release is published, an automated check scans every difference file for runs of
original game data and refuses to ship if it finds any.
