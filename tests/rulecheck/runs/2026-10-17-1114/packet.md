THE PACKET

Decision kind: build
Subject: huitzil.toml flavor_default 0x00 -> 0x01, then the M19 freeze
Claim (the working agent's sentence): Phobos's VS2/VH2 flavor latch RAM:$FF87C2 reads 0x01 on the native vsav2 leg and 0x00 on ours; with ours poked to 0x01, his part-1 rig reads 6851/6851 frames identical to native, and every consumer of the byte was enumerated in every addressing form (pristine vsavj: zero), so flavor_default becomes 0x01 and the five tracks are rebuilt and frozen as M19. Not tested: nothing further — the comparison is frame-exact over the whole part.
Artifacts (read every one, in full):
  - audit_move_parity.sh.txt (the gate that produced the 6851/6851 verdict; a shell script)
  - move_parity.tsv (its frozen per-part verdicts)
  - name_moves.py.txt (the rig generator both legs run; the pokes and cursor paths per tenant)
