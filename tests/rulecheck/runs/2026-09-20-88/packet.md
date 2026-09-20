THE PACKET

Decision kind: build
Subject: the release-side standalone completion of vsavjw.zip (route (c))
Claim (the working agent's sentence): Completing the SHIPPED vsavjw.zip with 7 pristine members (vm3.11m/12m/14m/16m/18m/20m from vsav.zip, dl-1425.bin from qsound_hle.zip), derived from gen_vsavjw_xml.PARENT_MEMBERS minus what the build authors plus the BIOS member, leaves the set a player runs behaviourally identical to the build the gates measure: on 05_timeout_idle (12,120 frames) the applied set ALONE in the rom path gives work RAM bit-identical on MAME and FBNeo and a bit-identical FBNeo framebuffer, MAME -verifyroms reports zero NOT FOUND from that one zip, WIDE bank 2 still reads pristine (the de-substitution invariant), and all 31 CRC-matched WIDE MRA parts resolve from it; the build, every fingerprint, every expectation set, every registry row and the MiSTer CRC pin are untouched. NOT TESTED: any replay other than 05_timeout_idle, any in-match or tenant-content replay, any MAME framebuffer comparison (VIDEO_OUT is asserted only inside the new test_release_binaries section 2b, whose own legs are MAME), MiSTer on hardware or in Verilator, the Windows and Linux release routes, and whether ZIP_STORED vs deflate (73.7 MB vs 28.0 MB) should change.
Artifacts (read every one, in full):
  - build/standalone_14z173.diff
  - tools/package_release.py
  - tests/test_release_roundtrip.sh
  - tests/test_release_binaries.sh
  - build/release_binaries_14z173.log
  - docs/project/release_format.md
