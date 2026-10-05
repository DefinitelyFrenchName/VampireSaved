THE PACKET

Decision kind: build
Subject: 14z-192: the M23 rows for #222 and #223 into huitzil.toml and donovan.toml
Claim (the working agent's sentence): Add the four M23 rows of build/agent192/m23/m23_rows_draft.toml to the tenant manifests (#222 in huitzil.toml: code_word air_dash_mask_hi at PRG:0x022AF4 2810->2811 and data_port air_dash_height_row writing vs2's row 0x10 at PRG:0x0BE25A; #223 declared identically in huitzil.toml and donovan.toml: code_word landing_bigbody_mask_hi_a/_b at PRG:0x003960 and 0x003B38 0448->0441), every row only_variant_slot, as ruled by the maintainer in build/agent192/m23/rulings_222_223.txt: build/agent192/m23/check_sites.txt shows vs2 and vh2 agreeing on each new value and merged-m22 holding vsavj's, and build/agent192/m23/idw192.log (tests/audit_id_writers.sh on PILOT, 22 of 22 tap logs complete) shows no legacy gameplay path writing an id in 0x10-0x1F, so the bits the rows change (id 0x10 set at all three mask sites, id 0x13 cleared at the two landing sites) belong to no legacy fighter in the corpus. NOT TESTED: the built images (no build yet — the freeze's rebuild, fingerprints and legacy oracle come after this); in play, only the air dash (tests/audit_air_dash_height.sh) and the landing site PRG:0x00395E (tests/audit_landing_sound.sh) were measured at 14z-191 — the second landing site PRG:0x003B36 is not reached by those rigs; the id-writer audit covers its corpus only (Oboro 0x18 is not exercised there, and the rows change neither bit 0x18 nor 0x12); in a solo build the other tenant's bit lands on an id no fighter carries, argued not measured; FBNeo.
Artifacts (read every one, in full):
  - build/agent192/m23/m23_rows_draft.toml
  - build/agent192/m23/check_sites.txt
  - build/agent192/m23/check_sites.py
  - build/agent192/m23/idw192.log
  - build/agent192/m23/rulings_222_223.txt
  - build/agent192/m23/engine_airdash_excerpt.txt
  - build/agent192/m23/engine_landing_excerpt.txt
  - tests/audit_id_writers.sh
