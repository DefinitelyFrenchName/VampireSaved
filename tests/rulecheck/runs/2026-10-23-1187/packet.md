THE PACKET

Decision kind: recommendation
Subject: #309 closed done: test_proof_sheets relative-unresolved fixed, measured on ERIS deep clone and the Mac (14z-206), after run 1186
Claim (the working agent's sentence): #309 can close done: its three to-dos (issue_309_body.md) are met. The fix: test_proof_sheets' section 3b makes its relative SHEET_OUT under the repository's build/ (mktemp, removed on exit), so the relative name carries no ".." and no longer depends on the repository path's depth, and a new check fails the gate if that name climbs out of the repository (relunres.diff; committed in 7b663645, whose section 3b is identical, line for line, to both fixed legs' gates: ERIS's (section3b_commit_vs_eris.txt) and the Mac's, rebuilt from 8b82d5d2 + relunres.diff to its recorded sha1 f32ab132 (section3b_commit_vs_mac.txt)). The control fires on both hosts the ticket names: on ERIS's deep clone (eris/legs.txt, eris/head.log, eris/fixed.log, eris/guard_reverted.log) the commit's gate has relative-unresolved DEAD, the fixed gate has it FIRED and PASSes, and the fixed gate with the old R3="$W/rel" line restored FAILs on the new check; on the Mac (legs.txt, deep.txt, REPORT.md) HEAD's gate is DEAD on a 9-deep logical path, the fixed gate FIRED there and PASSes on the plain tree in the default TMPDIR (its TMPDIR=/tmp leg ran in /var/folders/…/T/ too, because macOS mktemp -d ignores TMPDIR=/tmp, REPORT.md; so the shallow-/tmp case was measured on ERIS only), and the guard fails the restored old line (guard_reverted.log, from the command in guard_reverted.sh, recovered from the session transcript). No build/.proof_rel.* directory was left on either host. Not tested: PILOT was not rerun with the fix; the Mac's guard_reverted leg ran on the working tree's gate of that moment, whose sha1 was not recorded; the Mac's deep leg runs through a symlink, so its "relative rom path" FAIL is that rig's own (the gate's REPO is the logical pwd, the tool reads the physical path); and the commit's added #291 units and FOLLOWS line, which no #309 leg ran (test_proof_sheets is an emulator-tier gate, not in the static tier the commit passed).
Artifacts (read every one, in full):
  - build/agent206/t309/closing_comment.md
  - build/agent206/t309/issue_309_body.md
  - build/agent206/t309/REPORT.md
  - build/agent206/t291/relunres/relunres.diff
  - build/agent206/t309/section3b_commit_vs_eris.txt
  - build/agent206/t309/section3b_commit_vs_mac.txt
  - build/agent206/t309/eris/legs.txt
  - build/agent206/t309/eris/head.log
  - build/agent206/t309/eris/fixed.log
  - build/agent206/t309/eris/guard_reverted.log
  - build/agent206/t309/eris/eris_legs.sh
  - build/agent206/t309/eris/patch.out
  - build/agent206/t309/legs.sh
  - build/agent206/t309/legs.txt
  - build/agent206/t309/deep.sh
  - build/agent206/t309/deep.txt
  - build/agent206/t309/head_deep.log
  - build/agent206/t309/fixed_deep.log
  - build/agent206/t309/fixed_tmp.log
  - build/agent206/t309/fixed_default.log
  - build/agent206/t309/head_tmp.log
  - build/agent206/t309/guard_reverted.log
  - build/agent206/t309/guard_reverted.sh
  - tests/test_proof_sheets.sh.lines-200-240 (lines 200-240 of tests/test_proof_sheets.sh)
