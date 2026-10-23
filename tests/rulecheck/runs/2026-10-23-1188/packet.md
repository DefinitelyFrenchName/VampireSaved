THE PACKET

Decision kind: recommendation
Subject: #309 closed done: test_proof_sheets relative-unresolved fixed, measured on the committed gate on PILOT deep and the Mac (14z-206), after runs 1186-1187
Claim (the working agent's sentence): #309 can close done: its three to-dos (issue_309_body.md) are met, measured on the committed gate and tool. The fix (relunres.diff, committed in 7b663645) makes section 3b's relative SHEET_OUT under the repository's build/ and adds a check that fails the gate if the relative name climbs out of the repository. On PILOT, in a worktree of 7b663645 seven levels deep with no symlink, against a capture work dir five levels deep (commit_legs/pilot_legs.txt, pilot_legs.sh), 8b82d5d2's gate run with the committed tool has relative-unresolved DEAD and FAILs on that control alone (pilot_head.log), and the committed gate (sha1 e572f24a, tool sha1 048b4d1c) has it FIRED and PASSes (pilot_commit.log). On the Mac at 7b663645 the committed gate, the same sha1s, FIRES and PASSes (commit_legs/mac.txt, mac_commit.log), and a copy of it with the old R3="$W/rel" restored FAILs on the new climbs-out check (mac_guard.txt, mac_guard.log, mac_guard.sh, source sha1 recorded). No build/.proof_rel.* directory was left on either host. The earlier legs on ERIS (04a53769) and the Mac (8b82d5d2) ran their own trees' gate and tool and are context only; section 3b is identical across all three (section3b_commit_vs_eris.txt, section3b_commit_vs_mac.txt). Not tested: the Mac never runs a shallow /tmp work dir (macOS mktemp -d ignores TMPDIR=/tmp, REPORT.md), so the deep case rests on PILOT (and earlier ERIS); the earlier Mac deep leg's symlink gives a "relative rom path" FAIL that is that rig's own, while the committed-gate legs use no symlink.
Artifacts (read every one, in full):
  - build/agent206/t309/closing_comment.md
  - build/agent206/t309/issue_309_body.md
  - build/agent206/t309/REPORT.md
  - build/agent206/t291/relunres/relunres.diff
  - build/agent206/t309/commit_legs/pilot_legs.sh
  - build/agent206/t309/commit_legs/pilot_legs.txt
  - build/agent206/t309/commit_legs/pilot_head.log
  - build/agent206/t309/commit_legs/pilot_commit.log
  - build/agent206/t309/commit_legs/pilot_worktree.log
  - build/agent206/t309/commit_legs/mac.txt
  - build/agent206/t309/commit_legs/mac_commit.log
  - build/agent206/t309/commit_legs/mac_guard.sh
  - build/agent206/t309/commit_legs/mac_guard.txt
  - build/agent206/t309/commit_legs/mac_guard.log
  - build/agent206/t309/section3b_commit_vs_eris.txt
  - build/agent206/t309/section3b_commit_vs_mac.txt
  - build/agent206/t309/eris/legs.txt
  - build/agent206/t309/legs.txt
  - build/agent206/t309/deep.txt
  - tests/test_proof_sheets.sh.lines-200-240 (lines 200-240 of tests/test_proof_sheets.sh)
