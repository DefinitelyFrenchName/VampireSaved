# Vampire Saved: Full-Roster Vampire Savior (Extended CPS-2 spec, emulator-target, MiSTer as extended scope, EXPLORATORY, NOT FOR COMPETITIVE USE)

### This project is standing on the shoulders of the dedication of the Vampire Savior (and generally the Vampire series) community and the work of the CPS-2 wizards who came before me. Support them, support MAME and FBNeo and support Jotego without whom the MiSTer core for this larger CPS-II spec would have borderline impossible!

Disclaimer: This project is not really what it seems. At its core, and unlike my other romhacks, this project is purely an exercise to see if agentic engineering, driven as if addressing a black-box evolutive maintenance project (a domain I know quite a bit about) could deliver a demonstrably correct result. 

So, to be very clear: some of the memory analysis, all the decisions, the automated test harness design and a disgusting amount of testing was made by an organic brain. However all of the code was made by Claude, as was the implementation of the test harness.

Also, I was pretty much convinced I'd fail. I didn't and I have complicated feelings about it, although this also gives me hope for all the unreadable code we have in various industries because it sure feels as long as the codebase is sliced small enough, complexity is hardly an issue anymore...

## Goal

A modified CPS-2 (Japan - 970519) romset in which all 18 Vampire series characters are
selectable, running on the genuine Vampire Savior engine with byte-for-byte
vanilla behavior for all original content in 2P VS mode, playable in FBNeo (primary target)
and MAME (verification target), with a MiSTer CPS-2 core patch as a stretch goal.

N.B. As many of you know: this isn't just moving data, the CPS-2 does not have enough memory to hold all the 18 characters so the first step of the romhack is extending the CPS-2 specifications and tweaking the drivers accordingly. This extended specification is referred to as CPS-2 WIDE in the project

### Non-goals

- Real CPS-2 hardware support. The graphics address-space ceiling that forced
  Capcom to ship two split games would make that a hardware project; explicitly out
  of scope.
- New balance, new moves, new characters beyond the official 18, netplay
  features, or training-mode facilities. (A training hack already exists for
  vanilla vsav; compatibility with it is a nice-to-have, not a requirement.)
- Story-mode completeness for the ported three (endings, arcade-run cutscene
  parity) is a fully-optional stretch item within v1 polish, not a gate.

## Status

The needed CPS-II extended specification, its driver implementation in FBNeo and MAME are done
The MiSTer core is done, as an extension of Jotego's incredible CPS-II core.
The game iself is basically done, at least when it comes to 2P versus and
About 85% has been throroughly tested*, the remaining 15% is still on the roadmap 
*(and I don't mean playtesting, although there was some, I mean end-to-end either byte identical or within pre-approved tolerances, themselves measured against both games' engines)

### Implementation specifics
Though a competitive-ready is the goal, that seal of approval is not for me to give or take, only the community can.
Furthermore, officila tournament play is always on original releases so unless you want to use it in your locals, it intrinsically will never be up to that standard, and that is fine, it was always the dream, never the goal.

But let's talk practical details: 
- Vanilla Vampire Savior engine and characters, strictly unchanged.
- Donovan, Phobos and Pyron copied from VS2, with their Vampire Savior 2 data, including data that is unreachable in VS2 but was recovered, like their Dark Force activation invincibility. 
- HOWEVER ! Donovan, Phobos and Pyron use VS characters as shell to get injected into, which both simplified the issue of using them in VS but more importantly, it is the final key to guarantee they actually use the VS engine for anything that is not purely character-specific, including for their Dark Force: mapped to use their character-specific Dark Force from VS2 but burns only 1 bar of meter, has the VS background change, etc. as per the vanilla VS engine. 
- Using the VS engine also has a minor impact on the exact duration on some of their moves as VS and VS2 tick slighlty differently, making some multi-hits min/max hits potentially vary by 1, and similarly, some calculate damage values may vary by +/- 1 between this romhack and VS2.
- Last, there are minor known graphical glitches such as Donovan having no sword for P2 on the character select screen or his Press of Death EX having a chance of being a wrong palette. These are known and are currently tradeoffs to avoid impacting the original VS codebase massively enough to not warrant the risk.
- Random select and Shadow do include all characters including Donovan, Phobos and Pyron.
- Marionette has not been imported (needless impacts and risks)
- Win quotes are the shell character's quotes
- 1P mode is playable until the end as it doesn't crash but has seen no real care, on purpose: the stages will bear the names of the shell characters; fighting Pyron, Donovan or Phobos may cause the map to jump forward of back in stages before and/or after; their AI is noticeably worse than the other characters
- For fun: Oboro Bishamon has been made selectable by holding start while selecting Bishamon but his intro is so long you will only get control long after round start

Last but not least, while an awful lot has been tested, both by humans and machine alike, the game is not guaranteed perfect. The engine and vanilla characters are clean, all the moves have been checked but only specials, throws, ES and EX have been thoroughly tested, the rest is on the roadmap, at least for the data we have at least one reference of.
Also MAME, FBNeo and MiSTer are mechanically identical.

## Licence

Everything in this tree — tools, build manifests, patches, documentation
and authored assets — is released under the **GNU GPL v3.0** (`LICENSE`;
maintainer-ruled 2026-08-22). The MiSTer core is a fork of Jotego's
jtcores, itself GPL-3.0, so one licence covers the whole deliverable.
The licence covers OUR work only: no Capcom ROM content is in this tree
or in any artifact we distribute (next section, and CLAUDE.md rule 7).

## Legal and distribution stance

No ROM content is committed or distributed, ever. Deliverables are patches
against named commercial dumps, tools, and documentation. Contributors supply
their own reference sets. The repo documents findings, never extracted assets 
that could be used without the original code.
