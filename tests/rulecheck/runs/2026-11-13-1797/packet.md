THE PACKET

Decision kind: recommendation
Subject: #369/#310: close both, the 100-row debt list as #369's stated limit, on the 14z-227 blind reading of its modes
Claim (the working agent's sentence): Close #369 `done` with the 100 gates left on tests/expected/ctl_caught_debt.tsv as its stated limit, and #310 `done` with it, as the maintainer ruled ("agreed on both", given after the 9 unchecked flagged readings and the 4 unmeasured MiSTer modes were named to them; then, on the narrowings put back after rule-checker run 2026-11-13-1795 (the false OWN, the batches and static logs without a foreign-red control, the 5 non-OWN not shown), "Yes, close on these (Recommended)"; not put back: batches 1, 2, 7 and 8 lacking own-red controls, which can only lower the OWN count; DECISIONS_HISTORY.md "Ruled 2026-11-13 (14z-227) — #369 and #310 close"). Basis (build/agent227/close/evidence_a.md, written by script from the files it names, plus hand reads with their code and log lines): the 100 listed gates declare 352 modes; 348 were read blind from their latest logs (taken on 84cc5181 or 6dea53bc, trees that differ only in documents and rule-checker records, none read by an emulator debt gate: build/agent227/close/snapshot_diff.txt) by eight readers, one batch each, none of whom opened the key or another batch (transcript scan with a planted control: build/agent227/close/reader_access.txt), with 18 hidden controls of known own and known foreign reds, all read right; 343 of the 348 were read OWN (red from the check the declaration names), 4 OTHER, 1 CANNOT-TELL; one defect was found and filed as #373. NOT TESTED or NOT SHOWN: the 343 hold at least one false OWN, I044 (#373: a crash other than the declared one), and a reader's false OWN on a foreign red is uncontrolled in batches 3 and 4 (88 real items, own-red controls only) and was not caught in batch 2 (I044); batches 1, 2, 7 and 8 carried foreign-red controls only; all 18 controls are emulator-gate logs, so no control tested a false OWN on a static gate's log; the 5 non-OWN items are not shown to have gone red from their declared check (for four of them the same control fires in-gate on the plain run, which shows only that the check sees its fault on the plain run's data); the 4 MiSTer modes (no log); 9 OWN readings a reader flagged with a caveat were not checked by hand; a listed gate's mode stays HONOURED on any red, which the closing comments name as the limit.
Artifacts (read every one, in full):
  - build/agent227/close/evidence_a.md
  - build/agent227/close/snapshot_diff.txt
  - build/agent227/close/m310_score.txt
  - build/agent227/close/reader_access.py
  - build/agent227/close/reader_access.txt
  - build/agent227/close/reader_access_control.txt
  - build/agent227/m310/score.py
  - build/agent227/m310/key.tsv
  - build/agent227/m310/READER_BRIEF.md
  - tests/expected/ctl_caught_debt.tsv
  - DECISIONS_HISTORY.md.lines-10141-10184 (lines 10141-10184 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-11-13 (14z-227) — #369 and #310 close, with the 100-row debt list as #369's stated lim", and the entries after it up to line 10184)
  - docs/project/must_fire_contract.md.lines-146-159 (lines 146-159 of docs/project/must_fire_contract.md)
  - build/agent227/kc/mac_known_crash.log
  - tests/audit_release_linux_desktop.sh.lines-280-300 (lines 280-300 of tests/audit_release_linux_desktop.sh)
  - tests/audit_column_shock.sh.lines-290-300 (lines 290-300 of tests/audit_column_shock.sh)
  - tests/audit_tenant_continue_switch.sh.lines-92-192 (lines 92-192 of tests/audit_tenant_continue_switch.sh)
  - tests/audit_move_parity.sh.lines-640-690 (lines 640-690 of tests/audit_move_parity.sh)
  - build/agent227/m310/items/I189.mode.log
  - build/agent227/m310/items/I189.plain.log
  - build/agent227/m310/items/I179.mode.log
  - build/agent227/m310/items/I179.plain.log
  - build/agent227/close/c369.md
  - build/agent227/close/c310.md
