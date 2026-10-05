THE PACKET

Decision kind: expectation
Subject: 14z-192 M23 freeze: re-freeze test_mister_prg_window (the mark) and mame_parity_ab.tsv (replay 128)
Claim (the working agent's sentence): Re-freeze two expectations. (1) tests/expect/mister_prg_window.txt from the M23 MiSTer romset lane's own legs (build/emu_freeze_m23_mister/test_mister_prg_window.log; the legs copied to the session scratchpad) with --pos-log/--neg-log --freeze, keeping the file's history block by hand and adding a 14z-192 note. The pos line moved (cyc 97643614 -> 97642993, rd_lo 75765236 -> 75764560; every other pos field and the whole neg line unchanged) and the move is attributed by two separating controls (build/agent192/m23/attr/prg_window_attr.txt, ctl_fingerprints.txt): control A, M23's program with M22's graphics members (ctl_mark differs from merged-m22 only in vm3j.03d and vm3j.04d, and from merged-m23 only in vsw.33m and vsw.37m), PASSes against the frozen M22 pair (prgw_ctl_mark.log); control B, M23's graphics with M23's program minus #223's two landing rows (ctl_nolanding differs from merged-m23 only in vm3j.03d), measures exactly the M23 pair (prgw_ctl_nolanding.log). So on this replay (11_pick_donovan) the move follows the graphics members that carry the M23 mark, and #222/#223 contribute nothing. (2) tests/expected/mame_parity_ab.tsv by FREEZE=1 tests/test_mame_parity.sh on the Mac (the reference host), to freeze replay 128_shadow_vs_legacy_vsavj, which was added (84f56520, 14z-189) after the table's last freeze (9b551710, 14z-187b) and has no tests/expected/vsavj .sha1, so ERIS's M23 battery put it in section 2 and SKIPPED it for want of a reference binary (attr/mame_parity_attr.txt, attr/eris_test_mame_parity_m23.log). NOT TESTED: the mechanism by which graphics bytes move program-read counts; whether M22's unexplained move (recorded at 14z-189) was the M21 -> M22 mark (not re-run); the FREEZE=1 result itself, which follows this check and is verified by re-running without FREEZE.
Artifacts (read every one, in full):
  - build/agent192/m23/attr/claim_refreeze1.txt
  - build/agent192/m23/attr/prg_window_attr.txt
  - build/agent192/m23/attr/ctl_fingerprints.txt
  - build/agent192/m23/prgw_ctl_mark.log
  - build/agent192/m23/prgw_ctl_nolanding.log
  - build/emu_freeze_m23_mister/test_mister_prg_window.log
  - tests/expect/mister_prg_window.txt
  - tests/test_mister_prg_window.sh
  - build/agent192/m23/ctl_prg_build.sh
  - build/agent192/m23/ctl_drop_landing.py
  - build/agent192/m23/vsavjw_ctl_mark.xml
  - build/agent192/m23/vsavjw_ctl_nolanding.xml
  - build/agent192/m23/vsavjw_m23.xml
  - build/agent192/m23/attr/mame_parity_attr.txt
  - build/agent192/m23/attr/eris_test_mame_parity_m23.log
  - tests/test_mame_parity.sh
  - tests/expected/mame_parity_ab.tsv
