# engine_internals — HISTORY (blocks moved verbatim from `engine_internals.md`)

Moved by the documentation rationalization pass (14z-123 onward), one
document commit at a time. Rules: historical entries are not rewritten
(CLAUDE.md §5 [VSP-13] step 4); a correction is made where the live claim
lives, in `engine_internals.md`, and marked here only if it was already
marked when the block moved. Each block is headed by the section it left
and the commit that moved it, in the order it was moved. Blocks carry the
frontier language of their day: an "OPEN", "RETRACTED" or "ADOPTION
PENDING" here is the status AS IT WAS WRITTEN — the live document and
STATE carry the current one. No `**[PFX-N]**` anchor lives in this file.

## [14z-123 (b)] from «The WIN SCREEN subsystem — opener»

**Read this before touching any tenant's win screen.** Donovan's win
screen was fully solved in 14z-45; Huitzil's was then re-derived from
scratch in 14z-68 and got TWO of three pieces wrong, because the prior
analysis lived only in a session log. Everything a tenant needs is
below, with both characters as worked instances.

**WHICH FLOWS REACH IT (measured 14z-99, corrected by the maintainer the
same session):** the screen shows after match wins in BOTH 1P-vs-COM
(corner: PRESS START) and 2P (corner: the loser's CONTINUE countdown).
An earlier same-session reading — "a 2P-flow surface; 1P never shows it;
a legacy 2P winner skips it" — is RETRACTED: it came from two rig traps,
(a) coarse post-KO sampling landing on the MAP/tally screens that come
AFTER the win screen, and (b) mash inputs running past the KO pressing
through it (game gotchas, 14z-99). Rigs for this screen must end their
inputs at the KO and sample densely between the settle and the map.
**#105 — FIXED 14z-99 (`win_pal colors 8 -> 10`, all three builds — the
AUTO sets; gate `tests/audit_win_pal_auto.sh`; this line read KNOWN-OPEN
until 14z-114). The symptom as reported:** with AUTO (= auto-guard, a handicap
mode — the human still plays) selected by the WINNER, a TENANT winner's
portrait renders WHITE on the merged build: the `0x90C2A0` win-pal
window holds all-0xFFFF during the screen and the real colors arrive
AFTER it — the upload is LATE, not absent. Vanilla renders its AUTO
winner colored (not the engine's own behavior). Locked by
`tests/audit_win_pal_auto.sh` + `replays/103_tenant_2pwin_auto.rpl`.

## [14z-123 (b)] from «The WIN SCREEN subsystem — §3 the fetch index»

**RETRACTED (14z-73): `d0` is `0x40 + WINNER id`, not `0x60+id`.**
Breakpointing `0x5F328` at the actual win screen (replay 28 + forced
pick) measured `d0 = 0x50` for a Huitzil (id 0x10) win — so the slot is
`0x2672AA + 4*(0x40+id) - 4`; for id 0x10 that is `0x2673E6`. The
14z-68/NEXT_SESSION `0x60+id` (index `0x6F`, slot `0x267466`) was wrong;
repointing it changes nothing (measured — hui27 did exactly that and the
screen was unchanged). There is no separate P2 slot in evidence — the id
is the WINNER's, and the arcade win screen (the one with the CONTINUE
counter) always has a P1 winner.

## [14z-123 (b)] from «The WIN SCREEN subsystem — §3 the portrait array»

**The PORTRAIT already WORKS and is a DIFFERENT array from the quote.**
The `[[select_records]]` entry misnamed `win_quote` in `huitzil.toml`
ports Huitzil's victory PORTRAIT correctly (renders since hui16,
maintainer-confirmed hui26): it reads array `0x2A06E2` (index id, NO `-4`
bias) and pokes vsavj `0x2673ea` <- the placed vs2 `0x2A881E` = Huitzil's
portrait record (tiles bank-1 `0xb7xx`, pal 15-19). Its tiles ARE placed.
Do NOT touch it — a 14z-73 attempt to repurpose it for the quote stopped
poking `0x2673ea` and BROKE the portrait (self-inflicted "placeholder"),
reverted. The `d0=0x50 -> 0x2673E6` fetch measured at `0x5F328` was some
OTHER piece; poking `0x2673E6` changed neither portrait nor quote, so it
is not the lever for either.

## [14z-123 (b)] from «The WIN-QUOTE TEXT SYSTEM — §5 the retracted index-space reading»

**RETRACTED (mine, same session):** I first diagnosed this as the INDEX-SPACE
class — "table A is authored only to `0x1EF`, the tenant reads `0x263` in a
zero region and falls back to a default". That is wrong. **Table A
(`0xC912`, vs2 `0xB1EA`) is not the per-character selector at all** — it is a
special-matchup flag, near-entirely zero in BOTH games including for vs2's own
newcomers, its one non-zero being winner 0x01 vs loser 0x01 (a mirror match).
Zero there is the correct default, not a fallback. The deadness measurement I
took of that span is sound but measures a span the fix does not need.

## [14z-123 (b)] from «The projectile-pool HIT-CLASS map — adoption»

Fix — **ADOPTED, not pending** (corrected 14z-91; the "ADOPTION PENDING"
here contradicted HANDOFF's registry row for a whole session). The
`hitclass_map_extend` site_thunk is declared by `huitzil.toml:2048` and
`pyron.toml:1044` and is present in their builds; it was maintainer-adopted
2026-08-12 and huitzil-m4 / pyron-m3 were re-frozen on it.

## [14z-123 (b)] from «The projectile-pool HIT-CLASS map — the falsified deadness claim»

**Because it IS shipped, it is a live hook on a SHARED engine site**, and
**its "legacy never enters the map" evidence was FALSIFIED by measurement
(14z-92, M4).** That claim rested on two census replays, and both of them
happen to score zero. Over the 46-replay legacy corpus legacy enters the map
**230 times** (`24_don_winmash` 2, `26_don_arcade_mash` 228). The fix is
still sound and the argument is now the true one: every observed legacy index
is 0x02/0x04/0x09/0x0b, far below 64, so legacy reads VANILLA's own bytes out
of the thunk — "legacy enters constantly and receives vanilla answers", not
"legacy never enters". Corroborated by 43/46 bit-identical in the same run.
It was the same coverage shape that falsified the list-type 6 deadness claim
and produced the 14z-91 legacy regression, and this time it did fire. It is a `jmp` over `0x1A888` plus a
`cmpi.w`/`bcc` on every collision-map lookup. The dispatch is per-COLLISION,
not per-frame, so it is far colder than the obj_hook site was — but if a
legacy replay ever fails to re-converge and the walker relocation is not the
cause, look here next and re-run `tests/audit_hitclass_map_cost.sh`, whose
corpus IS the full 46 legacy pairings since 14z-92 (it had a four-replay
default until then).

## [14z-123 (b)] from «The projectile-pool HIT-CLASS map — the RETRACTED 14z-92 blockquote»

> **RETRACTED 14z-92.** This paragraph used to end "Legacy content measured
> entering this map ZERO times across four replays — the sweep serves
> secondary-object collisions vanilla content doesn't produce there." The
> four-replay figure was falsified by the corpus-wide run: legacy enters
> **230 times** (see the paragraph above). The sentence survived four lines
> below its own retraction for a session — the §5 failure mode exactly.

## [14z-123 (b)] from «THE CAPTURE-POSE INSTALLER — the superseded 'two exceptions' reading»

**(A superseded reading, kept for the record: "the two exceptions are the
useful part / read them first — their 32-entry tables are the shape the
fix needs" — RETRACTED the same session, 14z-99.** Zabel `0x04` and the
special slot `0x0B` do carry 32 distinct offsets at uniform `0x190`
stride, but their variant-half sub-blocks measure as BYTE-COPIES of the
base sub-blocks, 15/16 rows with `0x1F` the exception — the SAME defect
stored as materialized content, not populated tenant data.)

## [14z-123 (b)] from «THE CAPTURE-POSE INSTALLER — the 'MEASURED FEASIBLE' design-record framing»

**SHIPPED 14z-99 — the 15 `capture_kf` slot_rows data_ports
(`../project/patch_notes.md` "14z-99 — the window", gate
`tests/test_capture_pose_sources.sh`); this heading still read "MEASURED
FEASIBLE" until 14z-114.** The design record as it was written:
**THE FIX IS MEASURED FEASIBLE AND ITS SHAPE IS SETTLED (14z-99;
maintainer-ruled option (a) — full — conditioned on these measurements,
which came back clean; every premise below is frozen in
`tests/test_capture_pose_sources.sh`):**

## [14z-123 (b)] from «The DAMAGE pipeline — the +0x1D -> +0x17 correction note»

(copied from the hit record, byte **+0x17**
of the 0x20-stride hitbox/hitbox_proj records — CORRECTED 14z-120 (5): this
line said "+0x1D", an offset counted from the region start rather than the
record base; the shipped Huitzil rows at `hitbox_proj +0x17D/+0x19D` ARE
+0x17 of projectile records 5 and 6, see "Hitboxes and attack records")

## [14z-123 G2 #3] from «Reactions as the victim — the second step family sentence»

The
  sibling family at `0x27082` (three lists at `0x2797A`: 91 / 115 / 157 px,
  fast-decaying, counter `+0x1B0`) runs while `+0x185` is set — and
  `+0x185` is set on the OTHER fighter by `0x2681E` when a mash counter
  `+0x170` (`+= (d1>>1)+1` per input) reaches 10, together with a facing
  flip and `+0x171/+0x184/+0x5C/+0x3B5` on the masher: the shape of a THROW
  MASH-ESCAPE pushing the thrower away (read, not measured — 14z-121 (4)).
