# Vampire Saved: Full-Roster Vampire Savior (CPS-2, emulator-target, MiSTer as extended scope, EXPLORATORY, NOT FOR COMPETITIVE USE)

## Goal

A modified CPS-2 (Japan - 970519) romset in which all 18 Vampire series characters are
selectable, running on the genuine Vampire Savior engine with byte-for-byte
vanilla behavior for all original content, playable in FBNeo (primary target)
and MAME (verification target), with a MiSTer CPS-2 core patch as a stretch goal.

### Non-goals

- Real CPS-2 hardware support. The graphics address-space ceiling that forced
  Capcom to ship two split games makes this a hardware project; explicitly out
  of scope.
- New balance, new moves, new characters beyond the official 18, netplay
  features, or training-mode facilities. (A training hack already exists for
  vanilla vsav; compatibility with it is a nice-to-have, not a requirement.)
- Story-mode completeness for the ported three (endings, arcade-run cutscene
  parity) is a fully-optional stretch item within v1 polish, not a gate.

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
