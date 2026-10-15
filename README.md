# Vampire Saved

*"Worst of all, though, is that Vampire Savior never did get an all-in-one perfect competitive version that has all the characters together" -GuileWinQuote*

A forever true statement. But the FGC loves what ifs and this project attempts to answer the question: "But if we had, how would it be then?"

### Vampire Saved is Donovan, Phobos and Pyron, brought over from Vampire Savior 2 into the arcade Vampire Savior that competitive players use — with every original character left exactly as it was and everyone running the original engine.

### This project stands on the shoulders of the Vampire Savior community and of the CPS-2 wizards who came before it. Support them, and support MAME, FBNeo and Jotego — without Jotego's CPS-2 core, the MiSTer version of the larger board this needs would have been close to impossible.

***Disclaimer:** From its inception, this project has been an experiment in black-box agentic engineering, as in "regardless of the internals, can a demonstrably accurate result be obtained through guidance and an extensive testing harness. It just so happens that it's been applied to making a "Vampire Savior that could not be" instead of applying it to a more boring undocumented legacy program. As such the use of AI is intrinsically central and the main deliverable to its creator is not even the game but the work discipline and the test harness. But just because the ultimate goal isn't the game doesn't retract from the potential value of the game itself to anyone who values accuracy.*

[Play it](#play-it) · [What to expect](#what-to-expect) · [Report a problem](#report-a-problem) ·
[How it was made](#how-it-was-made)

## At a glance

|                                         |                                                              |
| --------------------------------------- | ------------------------------------------------------------ |
| **Base game**                           | Vampire Savior, Japan, 1997-05-19                            |
| **Roster**                              | The original Vampire Savior cast, plus Donovan, Phobos and Pyron from Vampire Savior 2. All characters run the Vampire Savior engine. |
| **Original characters and game engine** | Both unchanged. In 2-player versus their game state is checked frame by frame against the unmodified game, and matches it within a few small, measured tolerances (no frame of lag introduced, matching with the original games is guaranteed at same speed with same RNG). |
| **Plays on**                            | MiSTer (it also runs on a patched FBNeo or MAME but it's a more involved process) |
| **Made for**                            | 2-player versus. Arcade mode can be played to the end but    |
| **Tournaments**                         | **not** a tournament build. Tournaments run the community's choice which in this case is the original CPS-2 release. Even at perfect accuracy, this is aimed at casuals and locals|

**Why the emulator has to be patched:** the 18 characters do not fit in a stock CPS-2. The project
defines a larger CPS-2 (more room for program, graphics and sound) and adds it to FBNeo,
MAME and a MiSTer core. Stock emulators cannot run the game.

## Play it

No ROM data is distributed. You rebuild the game from your own dumps with a small script that checks
every byte before it writes anything.

**Download ONE package** from the [release page](https://github.com/DefinitelyFrenchName/VampireSaved/releases/). 
   (Make your life easier and play on MiSTer unless you *really* need emulation)
   Follow the documentation included in the zip file. 
   You'll need your own dumps, unmodified, with these exact names: `vsavj.zip` (Vampire
   Savior, Japan 970519), `vsav.zip` (Europe 970519) and `vsav2.zip` (Vampire Savior 2, Japan 970913).
   You also need Python 3.8 or newer — nothing else.

## What to expect

Everything in this build that differs from what you might expect is listed below, sorted by what it
is. Each line points to where it is tracked or explained — follow the link for the current details.

### How the three new characters work (by design)

- **Where their data comes from:** Vampire Savior 2 — their moves, damage and animation, including
  data that game ships but never reaches, such as their Dark Force activation invincibility.
- **Which rules they follow:** Vampire Savior's. Internally each new character is loaded into the slot
  of an existing one — its *shell* — so everything that is not specific to the character runs on
  Vampire Savior's engine.
- **Dark Force:** Dark Force is Savior's version: costs one bar and brings Vampire Savior's background change.
  The invulnerability for VS2 characters is lifted from their unreacheable VS2 code and the behavior is their personal DF from VS2.
- **Timing:** they run at Vampire Savior's game speeds. At factory settings NORMAL is the same speed as
  in Vampire Savior 2 and TURBO is one step slower. Compared at the same speed and with the same random
  draws, moves from Phobos, Donovan and Pyron match Vampire Savior 2 hit for hit and frame for frame. 
- **Potential gaps:** While the VS2 characters' movelists have been thoroughly tested, as well as most moves known to alter their sprites (throws, midnight bliss...),
  there still is the possibility of gaps in reactions or interactions (e.g. some DF interactions, some reactions to moves). Please open an issue if you find something I missed.
  
### Features and original behaviour you might take for bugs

- **Oboro Bishamon** is selectable (but impractical) : put the cursor on Bishamon, hold Start and confirm. His long intro
  is kept on purpose to not alter original assets, so you only get control after the round begins.
- **Dark Gallon and Shadow**, the original game's hidden characters, still work — and Shadow, who
  copies the opponent, copies the three new characters too.
- **Random select** can land on the three new characters.
- **The one-frame white flash at the first knockdown** is the original game's (if anyone can tell me why this exists...)

### Known limits and cosmetic issues

In versus:

- Donovan's **Press of Death** sometimes shows the wrong colours.
- On the select screen, **player 2's Donovan has an orange sword** — an accepted trade-off.
- The three new characters **use their shell's win quotes**.

In arcade mode (1 player) — never this project's scope; it plays to the end without crashing, and
that is all it promises.

Not included, or not planned:

- **Marionette** is not brought over.
  

## Report a problem

Open an [issue](https://github.com/DefinitelyFrenchName/VampireSaved/issues) and say which package you
used and which mark the select screen shows.

**If you can make it happen again, record it on MAME.** A recording lets the project replay your exact
session, frame for frame. Create two empty folders, `nvram_fresh` and `recordings`, then run the MAME
from your package (`cps2`, or `cps2.exe` on Windows):

    cps2 vsavjw -rompath "./rompath;/path/to/your/dumps" -nvram_directory ./nvram_fresh -input_directory ./recordings -record my_session.inp

Play until it happens, quit, and attach `recordings/my_session.inp` to the issue.

## How it was made

Vampire Saved is actually an experiment. It started as a work-adjacent project about **black-box agentic
engineering**: can AI agents, run the way you would run evolutive maintenance on a large system nobody can read
in full, deliver a result that is *demonstrably* correct?

The focus is purely accuracy of the end product and reliability of the harness..

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
  tested in simulation and on a real MiSTer.
- The new characters have no "original" to compare against in Vampire Savior, so they are compared
  with themselves in Vampire Savior 2, and between the two emulators.
- Every check carries a deliberate defect it must catch. A check that can no longer fail turns the run
  red — and a skipped check is never counted as a passed one.
- Every crash or misbehaviour a person can reproduce is captured first as a recording, then replayed
  against every new build.
- Every step that rests on a measurement — a fix, a freeze, a closed ticket — is first read by a separate
  AI checker that sees only the evidence files, never the working agent's reasoning, and that must also
  catch a deliberately flawed case planted beside the real one. Each objection it raises is answered in
  writing before the step goes ahead. At the end of every working session, the same kind of checker reads
  the session's transcript to confirm the agent did what it said and ran what it claimed.

**The scale, on 2026-10-15** (re-derive these rather than trusting this page): 461 test scripts, 
225 checks that need no emulator with 394 planted-defect controls executed at the last close, 
203 emulator and FPGA simulation checks, 233 scripted replays, 10 hand-played recordings of reported problems.


## Licence and legal

Everything in this repository — tools, build files, patches, documentation and authored assets — is
released under the **GNU GPL v3.0** (see `LICENSE`). The MiSTer core is a fork of Jotego's jtcores,
itself GPL-3.0, so one licence covers the whole deliverable.

The licence covers this project's own work only. **No Capcom ROM content is in this repository or in
anything it distributes**, in any form. Releases are patches against dumps you must already own; the
patches hold only bytes the port generates or authors, and a check scans every patch for original ROM
bytes before a release is published.
