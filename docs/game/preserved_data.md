# Preserved data — what the shipped ROMs carry but never reach

> **STATUS (opened 14z-126 at the maintainer's request, 2026-08-31):
> REFERENCE.** A catalogue of one class of fact about the three shipped
> games — `vsavj`, `vsav2`, `vhunt2` — DATA OR CODE THAT IS PRESENT IN A
> ROM BUT UNREACHABLE IN IT, established by measurement, with what the port
> does with it stated separately. It exists because the port keeps finding
> that what it "adds" was already there: repointing a row can RESTORE
> Capcom's own values rather than invent ours. Every entry says how it was
> measured and what is still unknown; the WHY of any port decision stays in
> `docs/project/`. The opposite class — rows a game ships as STUBS or ALIASES
> that a newcomer needs live (the dead-row class, [VSE-2]) — is
> `engine_internals.md`'s business, not this file's.

**How an entry qualifies:** (1) the bytes exist in the shipped ROM; (2) the
game has no path to them — measured, with a positive control, never
inferred from "no replay reached it" ([VSP-22]); (3) they are coherent
content (a handler that runs, a dataset that loads), not filler.

## 1. The VS-style Dark Force handler family in vs2 and vh2 — for all 18 characters (measured 14z-69c, 14z-126)

**What.** Vampire Savior's Dark Force is per-character: the activation body
sets seq `0x16` and the per-character handler selected by `dispatch_16`
(the 32-row code-pointer table, vsavj `PRG:0x0BF31A`) runs the character's
own activation — arming the victim-side invincibility timer `+0x147` with
that character's startup window, then its form (Huitzil's is a FLIGHT
mode). vs2 and vh2 replaced the DF system ([VSE-69]) — and kept the whole
family: their `dispatch_16` twins (vs2 `0x0D94B8`, vh2 `0x0D8D4A`) still
point every row at a VS-style handler, the 15 vanilla ones AND the three
newcomers' (vs2 `0x056C7A/0x058D28/0x05AE8C`, vh2
`0x056CB0/0x058D58/0x05AEBC`; the two sets differ only by pointer-shifted
operands, 4-7 bytes of 0x80).

**Why it is unreachable there.** vs2's activation body (`0x02619E`) writes
seq `0x16` and its per-character path clears it back to 0 in the SAME frame
(`0x025EE0`), so the seq-0x16 dispatch never fires; the DF-tick dispatcher
(vsavj `0x0BF61A`, vs2 `0x0D97B8`) is guarded on fields the vs2 body never
sets. Measured: native 0 hits at vs2 `0x056D70` with a positive control on
our leg (`engine_internals.md` "The two engines run DIFFERENT Dark Force
systems"); the native Donovan leg of `tests/audit_df_startup_invuln.sh`
never arms `+0x147` (vs2 writes 1 at `0x025F2A`, gone before frame_done).

**The values agree across the three ROMs.** `tests/test_df_startup_provenance.sh`
(ci_static): every vanilla row arms the SAME `+0x147` value in vsavj, vsav2
and vhunt2 (BU/DE 0x29, GA/AU 0x22, VI 0x3B, ZA 0x46, MO/AN/LI 0x3C, FE
0x2E, BI 0x2B, SA/QB 0x04, JE 0x7F — Lei-Lei's arm sits deeper than the
static window and is measured live), and the three newcomer rows arm
**Huitzil 0x4F, Pyron 0x29, Donovan 0x40** in BOTH vs2 and vh2 — not the
values of the vsavj rows they alias (Bulleta 0x29, Demitri 0x29, Victor
0x3B). The live windows, all 18, are frozen in
`tests/expected/df_startup_invuln.tsv`.

**What the port does.** Every built image repoints rows `0x10/0x11/0x13` to
the placed vs2 handlers (merged-m14: `0x41612A/0x4730E8/0x0C109C`), so on
this engine — where seq `0x16` survives — the newcomers' own handlers run
as written: their windows, Huitzil's flight form. The port did not author
these; it restored them.

**The maintainer's reading (2026-08-31, recorded as assessment):** the data
existed, and the port restored the values Capcom set for these characters
on this mechanism rather than inheriting the shells' — "incredibly lucky",
and evidence the port is likely as close as Capcom intended, balance
untested.

**Not known.** WHEN the handlers were written — before VS shipped (an
internal build with the three characters, cut with their data: the shipped
vsavj carries no trace of them, 14z-116) or during vs2/vh2 development on
the VS engine before the DF redesign. Huitzil's handler being a whole
flight-mode design the sequels discarded leans toward the former; it is a
lean, not evidence. And whether the values were ever balance-tested: dead
code in a shipped game may carry untuned numbers.

## 2. Oboro Bishamon's dataset in vsavj — complete, with no player-facing path (measured 14z-105, 14z-116)

**What.** Variant id `0x18` is a full character dataset in vsavj (record
base `0x0B3450`, its own palette block, 20 distinct bank rows;
`atlas/character_tables.md`, `atlas/select_screen.md`). The select commit
path accepts the id end-to-end and the match loads the base for P1 and P2.

**Why it is unreachable there.** The only immediate writes of a character
id in vsavj are `0x02`, `0x04`, `0x0B` and `0x12` — no vanilla path writes
`0x18` to `+0x382` (14z-116, a census of the writers). Dark Gallon `0x12`
is the contrast: vanilla's own hidden path (`PRG:0x020B9C`, Gallon + START
+ two or three punches or kicks) — reachable, therefore NOT this class.

**What the port does.** `oboro_select_hook` — Bishamon's cell + START held
at confirm commits `0x18`, vanilla's Gallon-variant idiom one cell over
(14z-105; gate `tests/test_oboro_select.sh`, field-confirmed). Removing the
hook would make Oboro unreachable again; Dark Gallon would not be affected.

**Not known.** Whether an entry path existed in a development build and was
removed, or was never written (the vs2 engine maps both Oboro-class ids
onto slot-8 CODE while keeping their own data rows, [VSE-17] — a different
arrangement, so vs2 does not answer it).

## 3. The third song class in the Z80 driver — executable, unused by both games (measured 14z-86)

**What.** Beside the multi-track song format the driver parses a FLAT
11-byte one-shot format (header byte0 = `0x80|voice`, parsed at Z80
`0x0311`). Zero of the 3,000+ live songs in either game use it.

**Why it is unreachable.** No id-table row in either game points at a
record of that class; the code path is entered only by a record that does.

**Measured.** Proven EXECUTABLE by an authored probe (14z-86: a hand-crafted
row keyed the exact record with the same keyon tuple as the multi-track
version) — `engine_internals.md` "Sound subsystem: the QSound command path".

**What the port does.** Nothing yet: the voice batch shipped verbatim
multi-track songs; the class is kept as a capability reserve.

## Candidates — seen in a listing, reachability not yet measured

- **A vsav-style DF field setter still in vs2** at `0x02622A`: writes
  `+0x111/+0x110/+0x143/+0x176` and fixed `+0x189` = 5 / `+0x188` = 0x23
  — the VS activation's field set, with constants where vsavj reads a
  per-character table (14z-126 listing). Whether anything reaches it is not
  measured; it may be the body the newcomers' DF used before the redesign,
  or an assembler leftover. A probe with a positive control decides.

An entry moves out of this list only with a measurement; a candidate that
turns out reachable is deleted, not kept.
