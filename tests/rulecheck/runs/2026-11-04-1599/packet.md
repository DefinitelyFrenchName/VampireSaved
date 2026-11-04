THE PACKET

Decision kind: expectation
Subject: M25: pass_overrun.tsv re-frozen for #345 A1b's accepted timing
Claim (the working agent's sentence): Re-freeze tests/expected/pass_overrun.tsv on merged-m25 (pass_overrun.tsv.diff): only ours rows move, donovan_2's overrun 3094 -> none and seven idle rows of donovan_2, donovan_10 and donovan_11 (their zero and mean figures), plus the build named in the header line; no native row changes. The moved lines equal, line for line, the ones measured on the 14z-219 scratch build build/agent219/t345a/mg (overrun_219_vs_m25.txt), whose program a24aa560 is merged-m25's (programs.txt); that build's timing was put to the maintainer and accepted, "Accept, freeze A1b (Recommended)" (DECISIONS_HISTORY.md "Ruled 2026-11-03 (14z-219) — #345: the built A1b's timing is accepted", REC_lostframes.md). The file was written by FREEZE=1 on ERIS at snapshot S3 (audit_pass_overrun.log) and verified by the S3 battery's plain run (verify_audit_pass_overrun.log: every row as frozen, the overrun-planted control fired; verify_row.tsv PASS). NOT tested: the idle-row moves on donovan_10 and donovan_11 were not put to the maintainer one by one (REC_lostframes.md reports zero-pass frames and held pictures, not idle means); FBNeo and MiSTer were not measured.
Artifacts (read every one, in full):
  - build/agent220/m25/rc/r_overrun/pass_overrun.tsv.diff
  - build/agent220/m25/rc/r_overrun/overrun_219_vs_m25.txt
  - build/agent220/m25/rc/r_overrun/programs.txt
  - build/agent220/m25/rc/r_overrun/audit_pass_overrun.log
  - build/agent220/m25/rc/r_overrun/verify_audit_pass_overrun.log
  - build/agent220/m25/rc/r_overrun/verify_row.tsv
  - build/agent220/m25/rc/r_overrun/REC_lostframes.md
  - DECISIONS_HISTORY.md.lines-9769-9786 (lines 9769-9786 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-11-03 (14z-219) — #345: the built A1b's timing is accepted; A1b freezes in M25 with #3")
