THE PACKET

Decision kind: recommendation
Subject: #350 closed done: publish_sheets.sh's upload under timeout --foreground, gated by test_proof_sheets_web section 2b (answer and Ctrl+C) and its no-foreground control (14z-217), after runs 2026-11-02-1570 and -1571
Claim (the working agent's sentence): #350 can close done with the closing comment closing_350.md. The issue (issue350.md) reports two symptoms of publish_sheets.sh's dry run: no password prompt, and Ctrl+C did nothing. The mechanism, GNU timeout without --foreground putting rsync/ssh in a process group that is not the terminal's foreground, is measured on this Mac in repro.txt (timeout is GNU coreutils 9.11; under a pty plain timeout never reads and exits 124 at 8 s, --foreground reads at once). The fix: tools/publish_sheets.sh's upload line reads 'timeout --foreground 3600 rsync' (fix.diff). tests/test_proof_sheets_web.sh section 2b (fix.diff) runs the publisher under a pseudo-terminal with a stub rsync that prints a prompt on /dev/tty and reads it; on the final fixed script the answer reaches the stub and the run finishes, and Ctrl+C sent at the prompt ends the publisher and the stub's process group within 5 s (gate5.log: both ok lines, PASS, 15 CONTROL FIRED). The must-fire control no-foreground, a copy with --foreground removed and TOOLS pointed at the real tools, must reach its upload (stub pgid file and prompt shown), lose the answer, and survive Ctrl+C for 5 s; the copy's Ctrl+C result was first measured as INTR-HUNG before the control asserted it (gate4.log MEASURE line); in-gate it reads CONTROL FIRED (gate5.log) and as a mode the gate FAILs on both checks (mode3.log). The control's first version fired without reaching the upload (the copy could not find proof_sheets.py), which is why it requires the stub to have started (evidence350.txt). NOT TESTED: a real ssh password prompt or a real ssh under Ctrl+C against the maintainer's site (needs the password; the next hand run at a release is the first real use); the 3600 s bound after the change (no run waited it out; with --foreground, ssh's ConnectTimeout bounds only the connection, and an ssh still at its prompt after the timeout is the hand-runner's to answer or Ctrl+C, as publish_sheets.sh's comment says); a Linux host (the gate ran on the Mac only); the change is uncommitted until the 14z-217 close commit, so the issue closes before the fix is on GitHub.
Artifacts (read every one, in full):
  - build/agent217/t350/closing_350.md
  - build/agent217/t350/issue350.md
  - build/agent217/t350/fix.diff
  - build/agent217/t350/evidence350.txt
  - build/agent217/t350/repro.txt
  - build/agent217/t350/gate4.log
  - build/agent217/t350/gate5.log
  - build/agent217/t350/mode3.log
  - tools/publish_sheets.sh
  - tests/test_proof_sheets_web.sh
