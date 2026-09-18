# NEXT SESSION — orientation (rewritten at the 14z-167 CLOSE, 2026-09-18)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE RULE-CHECKER RUNS ON OPUS 5 NOW (14z-167): Fable 5.1 was unreachable on the account's spend limit, so every fixture was recalibrated BY HAND under `--model claude-opus-5` (runs `2026-09-18-37`..`-40`, every plant caught, the negative OK). `tools/rulecheck.py` does NOT enforce a model change (**#158**): pass `--model <the resolved model id>` on every `prepare`, and before a real run check that the ledger holds calibration rows under that same model. A change of model, either way, is a recalibration (ruling 2026-09-17, 14z-163).

## 14z-166's re-freeze of `tests/expected/throw_registration.tsv` IS CHECKED (run `-41`, VIOLATED Q1 Q2 Q4, every finding true, resolved: the ids filter widened, a third control `double-write`, the tenant rows shown unchanged; the file did not move).

## #136's x FAMILY IS ATTRIBUTED, CAPTURE FIRST (14z-167): the three Phobos first-event rows are the round-start ENTRANCE (the rig's first X pin lands before the round starts; the maintainer identified the entrances on the capture); donovan_3's row is downstream of Killshread Summon (ES) pushing Demitri the wrong way — **#159**, the facing rule 5 vsavj's hit code lacks, gate `tests/audit_facing_rule.sh`. Both are on #136.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and release.
`git status -sb` says the push state. The withdrawn M19 build dirs are on disk,
UNREGISTERED — do not play them and do not point a gate at them.

## START HERE — what is open (THE ORDER IS RULED, 2026-09-17: stable state, then #148 (DONE), then #152 (DONE), then everything else — the #136 families included)

- **#136 — the Phobos guard-cancel rig.** huitzil_5/6/7 pin X at 2370, before the
  round starts at 2544 (`$FF812D`), so the entrance decides where the first event
  starts. The fix is a RIG change (the first pin after the round starts), then a
  re-freeze of the affected rows through the rule-checker; never a comparator
  tolerance. The later events of those parts first differ at +16/+17 on node/cnt,
  unattributed.
- **#136 — the cnt family.** On donovan_2 ev2 and donovan_10 ev1 BOTH fighters'
  node counters fall one tick behind on ours at the same frame, every other field
  equal: an engine tick lost on ours. Measure the pass counter `$FF8081` on both
  legs to separate a slowdown frame (our extra code) from the speed pattern's
  phase. Then donovan_11, huitzil_2/9, and huitzil_3's first event.
- **#157 and #159: the fixes are the maintainer's to schedule** (both
  needs-maintainer-ruling). #159's other rule-5 records (Donovan's `0xCA1CA`/
  `0xCA1EA`, `0xD17C2`/`0xD1822`) are unmeasured.
- **#158** (the checker's model binding), the in-DF rig change (agreed 2026-09-17),
  #157's two unmeasured tails, **#154/#155**, **#153**, **#150**: filed and unstarted.
- Every other open ticket is on `docs/project/tickets.md`; the harness has BBH-frame-based #1.

## TRAPS PAID THIS SITTING

1. **A rig pin written before the round starts is overwritten by the entrance**, and
   the entrance is drawn per leg — a first-event DIFF at +0 is a question about the
   rig's opening before it is one about the move (`docs/project/gotchas.md`).
2. **A word counter sampled as a byte reads its high byte**, and a flat field then
   "excludes" the mechanism it belongs to — the checker caught it (run `-42` Q3).
   Match a field's width to the instruction that reads it before excluding anything.
3. **A write tap on a field written many times a frame crashed MAME** while the tap
   log still had its END line — tap rare fields, sample hot ones with
   `field_trace.lua`, and check the emulator's exit status (`docs/platform/gotchas.md`).
4. **The parity gate's in-gate controls overwrite the FIRST part's saved inputs**
   (the 14z-164 trap, paid again on the rpl/pokes files): put a sacrificial part
   first in a scratch run (`build/x_family_14z167/audit_move_parity_keep.sh`).
5. **`rulecheck prepare`'s counter re-uses an id whose run dir has no ledger row**
   (run 36's NOT-RUN dir) — pass `--id`.
6. **Ask about frames where the legs have visibly separated, against the
   BACKGROUND** — the maintainer read the frames first asked about as identical;
   the difference showed later, and a companion who moves on her own (Anita) is no
   reference.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The
static tier is never run beside another gate run, or heavy work, in this tree.**
