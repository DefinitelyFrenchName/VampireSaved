THE PACKET

Decision kind: recommendation
Subject: #266 closed done: PILOT's Wayland restored on VirtIO-GPU and audit_release_linux_desktop PASSED there; the body's 'no graphics-stack package changed' corrected (14z-205c)
Claim (the working agent's sentence): #266 can close done: its to-do was (1) root-cause the crash (the stack trace first), (2) restore PILOT's Wayland session, (3) re-run audit_release_linux_desktop there so the next release carries its PASS. (2) is done (VirtIO-GPU display, a wayland session on seat0, pilot_apt_display.txt); (3) PASSED on 2026-10-20 with its three controls failing as modes (REPORT.md, normal.log and the mode logs), and the next release's own battery re-runs it; (1) is answered as far as measured: the crash was on the bochs card after the 2026-10-02 14:50 apt run upgraded the Mesa runtime, the stack trace was not read, and the card is no longer used, so nothing is left to do. The body's 'No graphics-stack package changed' is wrong and is corrected; the facts are homed in build_environments.md and gotchas.md and row 266 carries the four answers.
Artifacts (read every one, in full):
  - build/agent205c/t266/closing_comment.md
  - build/agent205c/t266/body_before.md
  - build/agent205c/t266/pilot_apt_display.txt
  - build/agent205b/t266/REPORT.md
  - build/agent205b/t266/comment.md
  - build/agent205b/t266/pilot_logs/normal.log
  - build/agent205b/t266/pilot_logs/muted-stream.log
  - build/agent205b/t266/pilot_logs/unlinked-recorder.log
  - build/agent205b/t266/pilot_logs/wrong-mark.log
  - docs/project/build_environments.md
  - docs/platform/gotchas.md.lines-3319-3328 (lines 3319-3328 of docs/platform/gotchas.md)
  - docs/project/tickets.tsv.lines-20-73 (lines 20-73 of docs/project/tickets.tsv)
  - docs/project/tickets.tsv.lines-109-109 (lines 109-109 of docs/project/tickets.tsv)
  - STATE.md.lines-41-51 (lines 41-51 of STATE.md)
  - STATE.md.lines-179-195 (lines 179-195 of STATE.md)
  - tests/audit_release_linux_desktop.sh
