THE PACKET

Decision kind: recommendation
Subject: #357 attributed (a type-0x13 watcher in the $FFD400 pool dispatched to vsavj's stub, shown at runtime) and a fix offered as an option on Huitzil's row-16 precedent, the maintainer's call
Claim (the working agent's sentence): Put to the maintainer recommendation_357.md: #357's cause is attributed — Donovan's round set-up (vs2 0x05AE3C, ported to ours 0x0C104C) creates a type-0x13 watcher in the $FFD400 pool, and vsavj's table for that pool points type 0x13 at a bare rts (0x080B44); measured on donovan_15 under the parity rig's pins: the same watcher and the same 181 trigger frames on both legs (measurer_357.txt); at runtime, on the opcodes space, each leg reads row 0x13 for its type-0x13 object from frame 2363, native's row holding 0x090EDA and ours 0x080B44, the live rows 0x01, 0x1B and 0x25 read on both legs as the tap's positive control, and native stamps type 0x72 sub 0x16 from 0x090FF4 (inside the handler's code, measurer_357.txt C3) 72 times from frame 2796 while ours has none (donovan_15.native.rows, donovan_15.ours.rows, measurer_357_rows.txt). The proposal, offered as an option, follows Huitzil's row-16 precedent (huitzil_row16_precedent.txt): port the handler, point row 0x13 at it with one [[code_ptr]], after measuring that vanilla never reads row 0x13; whether to build it is the maintainer's call under CLAUDE.md [VSP-10] (claude_vsp10.txt), the maintainer having confirmed the orbs as the defect (ruling_357_358.txt). NOT TESTED: whether vanilla ever reads row 0x13; whether our class-0x72 handler draws sub 0x16 (its records vs2 0x29C0C0-0x29C114); the handler's exact span and callees; its per-frame cost; the tap's read counts as dispatch counts (they are tap fires, equal on both legs, not interpreted); FBNeo and MiSTer; any part but donovan_15.
Artifacts (read every one, in full):
  - build/agent221/t357/rc/recommendation_357.md
  - build/agent221/t357/rc/measurer_357.txt
  - build/agent221/t357/rc/measurer_357_rows.txt
  - build/agent221/t357/rc/donovan_15.native.rows
  - build/agent221/t357/rc/donovan_15.ours.rows
  - build/agent221/t357/rc/d400_rows_tap.lua
  - build/agent221/t357/rc/engine_internals.diff
  - build/agent221/t357/rc/huitzil_row16_precedent.txt
  - build/agent221/t357/rc/ruling_357_358.txt
  - build/agent221/t357/rc/claude_vsp10.txt
