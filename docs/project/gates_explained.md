# The gates, explained plainly

This page explains the project's tests, which it calls **gates**, for a reader who knows nothing about the project. It
says what they check, how, and why some of their habits exist. For one line on every gate, see
[`gate_index.md`](gate_index.md); for how to write a gate's header, see
[`gate_header_contract.md`](gate_header_contract.md).

## The project in one paragraph

The project modifies the 1997 arcade game *Vampire Savior* to add three characters taken from its sister games
(*Vampire Savior 2* and *Vampire Hunter 2*). Its founding rule is that everything already in the original game must
behave exactly as it did: a match between two original characters must leave the game's memory byte-for-byte the same
as on the unmodified game (CLAUDE.md §1). Nobody can check that by eye, so the project proves it with gates, at every
change.

## What a gate is

A gate is a small script under `tests/`, nearly always a shell script, that prints one verdict:

- **PASS**: what it checks holds.
- **FAIL**: it does not, and the gate names what differs. A red gate stops forward work until it is fixed (CLAUDE.md
  §2, rule 6).
- **SKIP**: it could not run here, for example because a tool is missing. A SKIP is never a pass; a strict run counts it
  as red.

Many gates compare something produced now with a saved copy kept in the repository, under `tests/expected/`. The saved
copy is called a **frozen expectation**. A gate run with `FREEZE=1` writes it; every later run compares against it. If
the two differ, either something broke or the change was intended and the expectation is re-frozen after review.

Most gates also carry **controls**: deliberately broken inputs the gate must reject. A gate that can no longer fail
proves nothing, so each control is run and must "fire" (the gate must catch it). A control that does not fire reads
DEAD, and that is a failure too ([`must_fire_contract.md`](must_fire_contract.md)).

## The two kinds of gate

**Emulator gates** run the game itself, in the arcade emulators MAME and FBNeo, and in a simulation of the FPGA core
used on MiSTer hardware. They feed the game a scripted sequence of joystick and button presses, frame by frame, record
what it does (its memory every frame, the sprites drawn, the sounds played, a character's hits and damage), and compare
the result with the original game under the same inputs, or with a saved recording. The new characters have no
original to match, so their gates compare them against their home game and against each other across the two
emulators ([`oracle_classes.md`](oracle_classes.md) defines which comparisons are allowed). They are listed in
`tests/ci_emulator.tsv` and run by `tests/run_all_emulator.sh`; a full run takes hours and runs mostly on the remote
machines.

**Static gates** never start an emulator. They read files and run the project's tools. `tests/ci_portable.txt` lists the
ones a clean checkout can run with no game files at all; `tests/ci_static.txt` lists the ones that need the reference
game files or a built game. `tests/run_all_static.sh` runs both lists. They check:

- **the build**: the modified game is assembled from source descriptions, and must come out byte-identical every time
  from the same inputs;
- **the data**: the tables of moves, hitboxes and damage must match what was measured;
- **the documentation**: indexes, cross-references and ticket records must match the code;
- **the release packages**: each zip holds exactly the files it should;
- **the test machinery itself**: the runners, the verdict reader and the controls, each checked against cases whose
  answer is known.

## What they cover, by family

`gate_index.md` sorts every gate into one family:

| family | what its gates check |
|---|---|
| runner | the programs that run the gates, checked against known answers |
| docs | the documentation, skills, indexes and tables follow the code |
| platform | the emulators and the game files as measuring instruments: builds, decryption, replays that repeat exactly |
| pipeline | the build: its descriptions, its patch steps, and the extraction and generation of data |
| oracle | the original game's behaviour is preserved, frame by frame |
| gfx | tiles, sprites and what is drawn on screen |
| tenant | the three added characters, character by character |
| character-data | the map of every character's moves, hitboxes, reactions and projectiles |
| review-triage | the guards an adversarial review asked for, one per finding |
| mister | the MiSTer hardware core, its simulation and its packaging |

## When they run

- **Before a commit, and at every session close:** the whole static tier, in strict mode. A commit needs a recent
  all-green run of the exact tree it records ([`session_close.md`](session_close.md)).
- **At a freeze**, when a build is fixed as a milestone, and **at a release:** every gate, static and emulator, with
  every control.
- Some slow static gates run only at freeze or release ("cadence", in `tests/ci_cadence.tsv`), unless a file they read
  has changed.

## Why many gates sort their lists

Many lists a gate produces have no meaningful order of their own:

- a folder listing comes back in whatever order the file system keeps;
- emulator jobs run side by side finish in whatever order they finish;
- a search across many files, or a tool that collects its results into a set, has no fixed order either.

Compared as-is, such a list would fail whenever its order shuffled, even with identical contents. Sorting first makes
the comparison about what is in the list, not the order it arrived in. Two other uses appear in the scripts: the
standard commands that report "in A but not in B" (`comm`, `join`) need sorted input, which is how a gate reports that
a gate disappeared or that a zip holds a file the tree does not; and `sort -u | wc -l` counts how many different values
a list holds.

## The catch: sort order depends on the machine

The order the standard `sort` command produces, and the order `ls` lists in, depend on a machine setting called the
**locale**. Under the locale `C` (also `C.UTF-8`), text sorts by character code, called **byte order**: capitals come
before small letters, and `_` comes before letters. A "dictionary" locale such as `en_US.UTF-8` sorts the way a person
would, and Linux and macOS do it differently: Linux ignores punctuation on a first pass, so `ab` sorts before `a_c`,
where byte order puts `a_c` first; macOS keeps small and capital letters together (`a A b B`), where byte order puts
every capital first.

So a list saved on one machine and re-made on another can come out in a different order, and a gate comparing them
fails although nothing changed. Two gates did exactly that on the Linux machine in 14z-200 (#278). The three runners now
force byte order before they start any gate (`tests/lib/collation.sh`, checked by `tests/test_runner_collation.sh`), so
both sides of every comparison sort by the same rule. A gate run by hand outside the runners still sorts by its
terminal's locale; [`gotchas.md`](gotchas.md) (the UTF-8 collation entry) says when that can matter.
