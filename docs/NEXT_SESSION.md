# NEXT SESSION — orientation (rewritten at the 14z-169 CLOSE, 2026-09-18)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## #136's FIXES ARE ANALYSED, DESIGNED AND RULED GO (14z-169). The analysis in the maintainer's order found: the 0x52 rule works through a `+0x54` = 0x38 MARKER (nothing in vanilla produces it; every consumer reads it as 6) — not a remapped record; every defense read indexes the victim's own id (the defense-row fix is data only); only the three meter adders of the 26 `+0x1C3` readers play differently. The maintainer's condition on all four: *"the total overhead cost of our combined changes is less than 1/60s at all times"* — no new zero-pass frame (`$FF8081`, `tests/audit_pass_overrun.sh`) over the corpus against merged-m18.

## START HERE — the four #136 fixes are RULED GO (14z-169); they land TOGETHER WITH THE M19 FREEZE

Rulings (`DECISIONS_HISTORY.md` "Ruled 2026-09-18 (14z-169)"): all four fixes GO; the disabled EX
route does the no-stock (sub-pattern) move at every stock level; the 0x52 fix scoped S1.
**Why one freeze, not four green commits (found 14z-169):** a manifest change triggers
`test_m3a_reproducible` (the four tracks against the registered fingerprints) and every gate
targets the frozen merged-m18 — so the fixes, the registry rows, the tags, the re-point sweep, the
re-frozen expectations (each through the rule-checker) and the freeze battery (~5 h) are one piece
of work. Plan it as its own sitting(s): `vampire-saved-port` D.4 is the ritual.

1. **Gauge (#157's tail) — IMPLEMENTED AND VERIFIED, NOT COMMITTED:** `git apply
   build/rc169/fix1_gauge.patch` (one `[[port_patch]]` per tenant manifest, region `x028122`,
   `src_addr 0x028D6C`, `4a2e01c3` -> `4a2e0111`). Built 14z-169 into `build/m3b_merged27`
   (program key `04db6a44`, unregistered): the program image differs from merged-m18 in exactly
   3 bytes, the three adder tests. Moves: `audit_df_meter`, `test_df_field_readers`,
   `audit_df_field_readers_live`, `audit_df_moves` (gauge steps in the mode).
2. **Defense rows:** four `[[data_port]]` rows (Phobos and Donovan: the curve row from vs2
   `0x0D2ABE+id*32` to vsavj `0x0B8940+id*32`, 32 B; the threshold byte `0x0D6E1E+id` ->
   `0x0BCC80+id`), `only_variant_slot`, `dst_old_head`/`dst_end` guards. Moves
   `test_defense_rows_census`, `audit_defense_row_residue`, the move-parity DEFENSE-ROW rows.
3. **0x52 rule (S1):** drop donovan.toml's three `hitbox_proj` remaps (+0x291/+0x2B1/+0x2D1) and
   huitzil.toml's two trap remaps FOR THE MERGED COMPOSITION ONLY (a new generator row key, e.g.
   `unless_port = "donovan"`, with its unit test); `[reaction_hook] case_a4 = "137c003800544e75"`;
   `es_type51_dispatch` thunk: `cmpi.b #$52,d0` -> `addq.l #4,sp; jmp 0x0186E0`; the 14z-42 thunks:
   0x38 -> victim 0x18 (Donovan branch), attacker write skipped (default branch). Verify with
   `audit_column_shock`, `audit_trap_shock` (both re-freeze), the KO path (a column KO), and
   `test_reaction_classes` (the ours routes move).
4. **EX route:** force the placed Change entry's refusal (vs2 `0x2617A` in each `x026142` copy);
   `audit_ex_refused`'s ours stock-3 rows must then read the no-stock path.
5. **Then** the combined lag check (`audit_pass_overrun` over the corpus against merged-m18: no new
   zero-pass frame) and the freeze. File the tickets from `build/rc169/gh/` (rule-checker
   `recommendation` first, as `mechanyaa-ai`) — before or with the freeze.

## ALSO OPEN FROM 14z-168

- The static tier never checks that a `tests/ci_emulator.tsv` gate is EXECUTABLE:
  `tests/audit_df_field_readers_live.sh` was committed without `+x` (7603c86a) and only the
  emulator runner would have said so, at release (MISSING). Found at the 14z-168 close,
  when its static twin `test_defense_rows_census` read MISSING; both fixed. Add the check
  to a static gate.
- A static gate for the unsafe MAME-leg shape (a backgrounded leg writing its status
  under `set -e`; nine gates fixed by hand, `docs/project/gotchas.md`).
- bbh `selftest/test_fidelity_vampire.sh:356`: the F9 provenance pair pipes this tree's
  gate through `sed`, so our exit status reads 0 — a false difference on a red tree.
  Fix it in bbh (writable, pushes at a green close) or file it there.
- `build/manifest/huitzil.toml`'s "DEVIATION (maintainer-accepted …)" comment: update
  it in the 0x52 fix's commit (a manifest edit moves build fingerprints).
- #136's Phobos guard-cancel rig: the first X pin lands before the round starts — a
  RIG fix (the first pin after `$FF812D`), then a re-freeze through the rule-checker.
- #157, #159: the maintainer's to schedule; #158, #154/#155, #153, #150 filed and
  unstarted; every other open ticket is on `docs/project/tickets.md`.

## TRAPS PAID THIS SITTING (14z-169)

1. **A record's class byte is not the victim's reaction class** — the guard reads it, then a
   STAGER rewrites it before `+0x54`; read the whole chain before designing on a table entry.
2. **A manifest fix is not committable green between freezes** — `test_m3a_reproducible` is
   triggered by `build/manifest/`; fixes land WITH the freeze (`docs/project/gotchas.md`).
3. **The stager and reaction tables are 16-bit pc-relative** — a repointed entry cannot reach
   placed code; design through the port's own long-table thunks (`reaction_hook`).
4. **Look at a build directory before building into it** — `build/m3b_merged27` pre-existed.
5. **A fingerprint row must be the WHOLE-SET key** (`--set-key`); the program key is shared
   with `build/merged1` (rule-checker run 52).
6. **Name the play reading of a code fact as unmeasured** — "must be blocked low" was a
   conclusion without a hit or a capture (run 51 Q2).

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The
static tier is never run beside another gate run, or heavy work, in this tree.**
