# Vampire Saved

*"Worst of all, though, is that Vampire Savior never did get an all-in-one perfect competitive version that has all the characters together" -GuileWinQuote*

A forever true statement. But the FGC loves what ifs and this project attempts to answer the question: "But if we had, how would it be then?"

### Vampire Saved is Donovan, Phobos and Pyron, brought over from Vampire Savior 2 into the arcade Vampire Savior that competitive players use — with every original character left exactly as it was and everyone running the originla Vampire Savior engine.

### This project stands on the shoulders of the Vampire Savior community and of the CPS-2 wizards who came before it. Support them, and support MAME, FBNeo and Jotego — without Jotego's CPS-2 core, the MiSTer version of the larger board this needs would have been close to impossible.

***Disclaimer:** From its inception, this project has been an experiment in black-box agentic engineering. It just so happens that it's been applied to making a "Vampire Savior that could not be" instead of applying it to a more boring legacy program. As such the use of AI is intrinsically central and the main deliverable to its creator is not even the game but the work discipline and the test harness. But just because the ultimate goal wasn't the game doesn't change the value of the game itself.*

[Play it](#play-it) · [What to expect](#what-to-expect) · [Report a problem](#report-a-problem) ·
[How it was made](#how-it-was-made) · [Find your way around](#find-your-way-around)

## At a glance

|                                         |                                                              |
| --------------------------------------- | ------------------------------------------------------------ |
| **Base game**                           | Vampire Savior, Japan, 1997-05-19 — the version competitive play uses |
| **Roster**                              | The original Vampire Savior cast, plus Donovan, Phobos (Huitzil in Japan) and Pyron from Vampire Savior 2. All characters run the Vampire Savior engine. |
| **Original characters and game engine** | Both unchanged. In 2-player versus their game state is checked frame by frame against the unmodified game, and matches it within a few small, measured tolerances. |
| **Plays on**                            | a patched FBNeo or MAME (ready-made for Windows 10+ and Apple-silicon Macs on macOS 26+, or build it yourself on anything else), and MiSTer |
| **Current release**                     | `merged-m18` — the character-select screen shows **M18** in its bottom-right corner |
| **Made for**                            | 2-player versus. Arcade mode can be played to the end but    |
| **Tournaments**                         | not a tournament build. Tournaments run original releases; this is for casuals, labs and locals |

**Why the emulator has to be patched:** the 18 characters do not fit in a stock CPS-2. The project
defines a slightly larger CPS-2 — more room for program, graphics and sound — and adds it to FBNeo,
MAME and a MiSTer core. Stock emulators cannot run the game.

## Play it

No ROM data is distributed. You rebuild the game from your own dumps with a small script that checks
every byte before it writes anything.

1. **Download ONE package** from the
   [release page](https://github.com/DefinitelyFrenchName/VampireSaved/releases/tag/freeze/merged-m18).
   Each one is complete.

   | package                                                      | pick it if you play on                                       |
   | ------------------------------------------------------------ | ------------------------------------------------------------ |
   | `merged-m18-fbneo-windows-x86_64.zip` or `merged-m18-fbneo-macos-arm64.zip` | FBNeo — the patched emulator is inside, ready to run         |
   | `merged-m18-mame-windows-x86_64.zip` or `merged-m18-mame-macos-arm64.zip` | MAME — the patched emulator is inside, ready to run          |
   | `merged-m18-fbneo-recipe.zip` or `merged-m18-mame-recipe.zip` | any other system — the emulator patch and the steps to build it once |
   | `merged-m18-mister.zip`                                      | MiSTer — the core and its menu entries                       |

2. **Gather your dumps** in one folder, unmodified, with these exact names: `vsavj.zip` (Vampire
   Savior, Japan 970519), `vsav.zip` (Europe 970519) and `vsav2.zip` (Vampire Savior 2, Japan 970913).
   You also need Python 3.8 or newer — nothing else.

3. **Build the game:**

       python3 apply_release.py --romdir /path/to/your/dumps --out ./rompath

   This writes `rompath/vsavjw.zip`. A wrong or modified dump is refused by name.

4. **Play:**

   - **FBNeo:** put `vsavjw.zip` and your untouched `vsav.zip` in the `roms/` folder next to the
     emulator, and start `vsavjw`.
   - **MAME:** point the rom path at both the same way, and start `vsavjw`.
   - **MiSTer:** copy the core and the two `.mra` files as the package's README says, put
     `vsavjw.zip`, `vsav.zip`, `vsavj.zip` and `qsound.zip` in `games/mame/`, and launch
     *Vampire Saved - CPS-2 WIDE*.

   The boot screen reads **VAMPIRE SAVED**.

**If it does not start:** "unknown system" means the emulator is not the patched one. A game frozen on
the QSound/CAPCOM screen means the set was renamed to force it into a stock emulator — renaming is
never the fix. For netplay, every player needs the same emulator build and the same romset. Each
package's own `README.md` has the full steps.

## What to expect

Everything in this build that differs from what you might expect is listed below, sorted by what it
is. Each line points to where it is tracked or explained — follow the link for the current details.

### How the three new characters work (by design)

- **Where they are:** a new row of three medallions below the character wheel.
- **Where their data comes from:** Vampire Savior 2 — their moves, damage and animation, including
  data that game ships but never reaches, such as their Dark Force activation invincibility.
- **Which rules they follow:** Vampire Savior's. Internally each new character is loaded into the slot
  of an existing one — its *shell* — so everything that is not specific to the character runs on
  Vampire Savior's engine: Dark Force costs one bar and brings Vampire Savior's background change.
- **Timing:** they tick on Vampire Savior's engine clock, not Vampire Savior 2's, so a move can span a
  different number of video frames than in Vampire Savior 2 while its hits and damage match
  ([#114](https://github.com/DefinitelyFrenchName/VampireSaved/issues/114); the two clocks are being measured in [#135](https://github.com/DefinitelyFrenchName/VampireSaved/issues/135)).

### Features and original behaviour you might take for bugs

- **Oboro Bishamon** is selectable: put the cursor on Bishamon, hold Start and confirm. His long intro
  is kept on purpose, so you get control after the round begins ([standing rulings](STATE.md#standing-rulings)).
- **Dark Gallon and Shadow**, the original game's hidden characters, still work — and Shadow, who
  copies the opponent, copies the three new characters too ([select screen notes](docs/game/atlas/select_screen.md)).
- **Random select** can land on the three new characters ([port registry](docs/project/patch_index.md)).
- **The one-frame white flash at the first knockdown** is the original game's, not this project's
  ([#113](https://github.com/DefinitelyFrenchName/VampireSaved/issues/113)).
- **Pyron's Cosmo satellites do not collide with other projectiles** — the same as in Vampire Savior 2
  ([#108](https://github.com/DefinitelyFrenchName/VampireSaved/issues/108)).

### Known limits and cosmetic issues

In versus:

- Donovan's **Press of Death** sometimes shows the wrong colours ([#112](https://github.com/DefinitelyFrenchName/VampireSaved/issues/112); a cleaner fix is tracked
  as [#127](https://github.com/DefinitelyFrenchName/VampireSaved/issues/127)).
- On the select screen, **player 2's Donovan has an orange sword** — an accepted trade-off
  ([port registry](docs/project/patch_index.md)).
- The **extended character wheel** works but its look is not polished ([#126](https://github.com/DefinitelyFrenchName/VampireSaved/issues/126)).
- The three new characters **use their shell's win quotes** ([#123](https://github.com/DefinitelyFrenchName/VampireSaved/issues/123)).

In arcade mode (1 player) — never this project's scope; it plays to the end without crashing, and
that is all it promises:

- The **stage names and pictures** on the arcade map are the shell characters' ([#125](https://github.com/DefinitelyFrenchName/VampireSaved/issues/125)).
- The **opponent roulette** shows the shell instead of the new character ([#124](https://github.com/DefinitelyFrenchName/VampireSaved/issues/124)).
- The **next-stage screen** shows Donovan as Victor, with a blank portrait ([#100](https://github.com/DefinitelyFrenchName/VampireSaved/issues/100)).
- The three new characters' **CPU AI** feels weaker than the rest of the cast ([#129](https://github.com/DefinitelyFrenchName/VampireSaved/issues/129)).
- Playing an original character, **you never face one of the three** — not built, by choice
  ([standing rulings](STATE.md#standing-rulings)).

Not included, or not planned:

- **Marionette** is a Vampire Savior 2 character and is not brought over ([#128](https://github.com/DefinitelyFrenchName/VampireSaved/issues/128)).
- **Not planned:** real CPS-2 hardware (the board's limits would make that a hardware project),
  balance changes, new moves, characters beyond the official 18, or a training mode.

The full, current list of tracked bugs, cosmetic items and planned work is
[`docs/project/tickets.md`](docs/project/tickets.md).

## Report a problem

Open an [issue](https://github.com/DefinitelyFrenchName/VampireSaved/issues) and say which package you
used and which mark the select screen shows.

**If you can make it happen again, record it on MAME.** A recording lets the project replay your exact
session, frame for frame. Create two empty folders, `nvram_fresh` and `recordings`, then run the MAME
from your package (`cps2`, or `cps2.exe` on Windows):

    cps2 vsavjw -rompath "./rompath;/path/to/your/dumps" -nvram_directory ./nvram_fresh -input_directory ./recordings -record my_session.inp

Play until it happens, quit, and attach `recordings/my_session.inp` to the issue.

## How it was made

Vampire Saved is also an experiment. It started as a work-adjacent project about **black-box agentic
engineering**: can AI agents, run the way you would run maintenance on a large system nobody can read
in full, deliver a result that is *demonstrably* correct?

**Who did what.** All of the code was written by AI — Anthropic's Claude, through Claude Code.
All of the decisions, the design of the test harness, part of the memory analysis and a very large
amount of hands-on testing were done by a human brain. Work was accepted only on evidence, never on the agent's word.

**What "correct" means here.** One rule defines the project: any match, menu or attract sequence that
does not involve the three new characters must leave the game in the same state as the unmodified
game, frame after frame. A change that improves a new character but moves one byte of original
behaviour is a failed change, not a trade-off.

**How that is checked.**

- Scripted input replays are played on the original game and on the modified one, and the game's
  memory is compared every frame (in MAME). FBNeo cross-checks on samples, and the MiSTer core is
  tested in simulation and on real hardware.
- The new characters have no "original" to compare against in Vampire Savior, so they are compared
  with themselves in Vampire Savior 2, and between the two emulators.
- Every check carries a deliberate defect it must catch. A check that can no longer fail turns the run
  red — and a skipped check is never counted as a passed one.
- Every crash or misbehaviour a person can reproduce is captured first as a recording, then replayed
  against every new build.

**The scale, on 2026-09-15** (re-derive these rather than trusting this page): 1,596 commits over
seven and a half weeks, more than 150 working sessions, 331 test scripts, 154 checks run before every
commit with 172 planted-defect controls executed at every session's close, 173 emulator and FPGA
simulation checks, 184 scripted replays, 7 hand-played recordings of reported problems, and 140 tracked tickets.

**What all that green does not prove.** It does not prove that the new characters *feel* right —
only players can judge that. The frame-by-frame guarantee covers the scripted replays, not every match
anyone could play. And a few original sequences are allowed small, measured and frozen tolerances,
because code added to reach the new characters costs the processor time. A move-by-move comparison of the three
new characters with Vampire Savior 2 is tracked separately ([#136](https://github.com/DefinitelyFrenchName/VampireSaved/issues/136)).

**Lineage.** The working discipline began in a Super Nintendo project,
[Sailor Moon S — FrenchName edition](https://github.com/DefinitelyFrenchName/SMS-FrenchName-edition),
and was scaled up here. The test harness was then extracted into its own project,
[BBH](https://github.com/DefinitelyFrenchName/BBH-frame-based), for anything that can be driven frame by frame, and generalised again as [BBX](https://github.com/DefinitelyFrenchName/BBX), for any work whose
result has to be proven to someone who cannot read how it was made.

## Find your way around

| file                                                 | what it is                                                   |
| ---------------------------------------------------- | ------------------------------------------------------------ |
| [`docs/README.md`](docs/README.md)                   | the map of the documentation, in three halves: the game itself, the CPS-2 board and its emulators, and this port |
| [`HANDOFF.md`](HANDOFF.md)                           | how to build everything from source, run the tests and play a development build |
| [`CLAUDE.md`](CLAUDE.md)                             | the rules every change follows, whoever writes it            |
| [`STATE.md`](STATE.md)                               | what the latest working sessions did, and the rulings in force |
| [`docs/project/tickets.md`](docs/project/tickets.md) | every known bug, cosmetic item and planned evolution, each with its GitHub issue |

## Licence and legal

Everything in this repository — tools, build files, patches, documentation and authored assets — is
released under the **GNU GPL v3.0** (see `LICENSE`). The MiSTer core is a fork of Jotego's jtcores,
itself GPL-3.0, so one licence covers the whole deliverable.

The licence covers this project's own work only. **No Capcom ROM content is in this repository or in
anything it distributes**, in any form. Releases are patches against dumps you must already own; the
patches hold only bytes the port generates or authors, and a check scans every patch for original ROM
bytes before a release is published.
