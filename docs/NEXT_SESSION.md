# NEXT SESSION — orientation (rewritten at the 14z-170 CLOSE, 2026-09-19)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## M19 IS FROZEN (14z-170): the four ruled #136 fixes and the x2b7ef4 repair — donovan-m23 / huitzil-m30 / pyron-m24 / merged-m19, `build/m3b_merged27`

What it carries: no gauge in the tenants' Dark Force; vs2's defense rows for Phobos and Donovan;
the vs2 EX inputs do the no-stock move (Pyron's reads 623+PP, ruled natural); the class-0x52 rule
(column and — on merged — trap), scope S1; and the `x2b7ef4` companion-effect records the
generator's in-place scan had corrupted since at least merged-m16. HANDOFF "Current WIDE builds"
and patch_notes 14z-170 have the detail; STATE 14z-170 the record.

## START HERE

1. **M19 IS FROZEN, NOT RELEASED — and the release WAITS, by ruling (2026-09-20):** *"let's not
   release now, especially since we have tickets relative to the deliverables on various OS"*. The
   blockers are **#144** (macOS blocks the prebuilt binaries), **#145** (Windows: they fail to load)
   and **#146** (the player READMEs), each reported and none yet reproduced. When they are done, the
   release run is `--scope all --lane all --strict --controls` (~5.5 h, HANDOFF "WHAT THE RELEASE RUN
   COSTS"), then `tools/upload_release_assets.sh` on `freeze/merged-m19`. `release/merged-m19/` is
   packaged and gated in-tree; the freeze tags and registry rows stand.
2. **The orange flash** (the cosmetic ticket #162; `tests/audit_column_flash.sh` freezes it): our build
   uploads palette row 11 through the palette-SEQUENCE uploader at 2858, where native does not upload.
   The open question is which sequence id it asks for, and why (the +8 row remap between the games,
   `engine_internals.md` "The palette-SEQUENCE uploader"). The answer decides whether it is local or wider.
3. **Phobos's remaining +1** (the bug ticket, #161; `tests/audit_phobos_dmg_residual.sh` reproduces it): Demitri's 5HP
   takes 12 on ours, 11 native, with Phobos's defense rows already vs2's — trace the damage staging vars stage by stage on
   both legs for that one hit (`docs/game/engine_internals.md` "The DAMAGE pipeline").
4. **The #136 tickets still open**: #157 (the throw hit-registration pair — the meter family), #159
   (facing rule 5), #163 (the column/trap rule: its airborne case), and the rig items below; the maintainer's to schedule.

## ALSO OPEN (carried from 14z-168/169)

- The static tier never checks that a `tests/ci_emulator.tsv` gate is EXECUTABLE (a gate committed
  without `+x` reads MISSING only at release). Add the check to a static gate.
- A static gate for the unsafe MAME-leg shape (a backgrounded leg writing its status under
  `set -e`).
- bbh `selftest/test_fidelity_vampire.sh:356`: the F9 provenance pair pipes this tree's gate
  through `sed`, so our exit status reads 0 — a false difference on a red tree.
- #136's Phobos guard-cancel rig: the first X pin lands before the round starts — a RIG fix, then
  a re-freeze through the rule-checker.
- A column hit on an AIRBORNE victim (the air stager's case) is not measured — #163's one open item (the column KO read clean on the capture, 2026-09-19).

## TRAPS PAID THIS SITTING (14z-170)

1. **Attribute a freeze's program delta op by op** (`tools/attribute_patch_delta.py`) — "the fix
   moved N bytes" hid 52 corrupted records inside the relocation noise.
2. **The MiSTer tail comes BEFORE the MiSTer lane** — a stale fork catalogue fails every romset
   MiSTer gate in seconds.
3. **A BEFORE measurement runs the before-tree's own tool.**
4. **`sh -n` a perturbed gate copy before reading its verdict** — a syntax error exits 0.
5. **Freeze hashes, never ROM-derived bytes** (palette, tile, record content).
6. **An unpinned rig is not "the move starts later"** — pin the speed level and the RNG on every
   ours-vs-native timeline (vs2 runs TURBO by default).
7. **A fix that moves a frozen value has to land on NATIVE, not just move away from the defect**: compare every
   moved row with native before re-freezing.
8. **A damage fix re-times every rig that waits for a KO** (win-pal, continue-switch): find the event per build.
9. **A `-debug` watch's frame column counts debugger STOPS, not frames ([CPE-5], paid TWICE this
   sitting):** the orange flash's writer and the x2b7ef4 reachability were both misread from it. For WHEN,
   use the non-debug tap (`read_tap.lua`); for a "never read", watch only the bytes in question, arm
   late, and check the run's node trajectory against a non-debug run (`tests/audit_x2b7ef4_reach_m18.sh`).

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]).
