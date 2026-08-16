# donovan-m2 stage 6 — generated op notes

# stage 1: Jedah hitbox block 0x091E58+0x0 (base 0x91f98 comp 0x91e58)
# table_fix: region x026142 len 0x1400 -> 0x1440 (ported per-char OBJ bank table -> vanilla vsavj values + row 0x10 = WIDE bank 4)
# layout group at 0xbf6a0+0x79c6: code@0xbf6a0, x057456@0xc1e66; 0x0 gap bytes recycled
data_file 0x0d8690 +0x1e800  donovan anim (from vsav2 0x245872)
data_file 0x0f6e90 +0x190  donovan aux0_0 (from vsav2 0x334170)
data_file 0x3ec720 +0xe620  donovan aux0_1 (from vsav2 0x336560)
# code+0x9c: pcrel16 -> x057456@0x574b0 (disp 0x2784 -> 0x2784 after placement)
# code+0x102: pcrel16 -> x057456@0x574b0 (disp 0x271e -> 0x271e after placement)
# code+0x15a: pcrel16 -> x057456@0x574b6 (disp 0x26cc -> 0x26cc after placement)
# code+0x1a4: pcrel16 -> x057456@0x574b6 (disp 0x2682 -> 0x2682 after placement)
# code+0x2f4: pcrel16 -> x057456@0x574b0 (disp 0x252c -> 0x252c after placement)
code   0x0fafd0 farm-port stub for 0x2916c (param at 0x0fafb0, common 0x29f4a)
code   0x0faff0 farm-port stub for 0x29184 (param at 0x0fafe0, common 0x29f4a)
code   0x0fb010 farm-port stub for 0x2918c (param at 0x0fb000, common 0x29f4a)
code   0x0fb020 slot-clearing alloc wrapper for 0x15702 -> 0x16fba (0x80 cleared, +8 preserved)
# code+0x9ac: pcrel16 -> x057456@0x574b0 (disp 0x1e74 -> 0x1e74 after placement)
# code+0xd3a: pcrel16 -> x057456@0x574b0 (disp 0x1ae6 -> 0x1ae6 after placement)
# code+0xfe2: pcrel16 -> x057456@0x574b0 (disp 0x183e -> 0x183e after placement)
# code+0x10da: pcrel16 -> x057456@0x574b0 (disp 0x1746 -> 0x1746 after placement)
# code+0x141a: pcrel16 -> x057456@0x574b0 (disp 0x1406 -> 0x1406 after placement)
# code+0x142a: pcrel16 -> x057456@0x574b0 (disp 0x13f6 -> 0x13f6 after placement)
# code+0x151a: pcrel16 -> x057456@0x574b0 (disp 0x1306 -> 0x1306 after placement)
# code+0x18d0: pcrel16 -> x057456@0x574b0 (disp 0xf50 -> 0xf50 after placement)
# code+0x18e0: pcrel16 -> x057456@0x574b0 (disp 0xf40 -> 0xf40 after placement)
# code+0x197c: pcrel16 -> x057456@0x574b0 (disp 0xea4 -> 0xea4 after placement)
# code+0x1a38: pcrel16 -> x057456@0x574c2 (disp 0xdfa -> 0xdfa after placement)
# code+0x1a46: pcrel16 -> x057456@0x574c2 (disp 0xdec -> 0xdec after placement)
# code+0x1a86: pcrel16 -> x057456@0x574c2 (disp 0xdac -> 0xdac after placement)
# code+0x1b94: pcrel16 -> x057456@0x574b0 (disp 0xc8c -> 0xc8c after placement)
# code+0x1c94: pcrel16 -> x057456@0x574b0 (disp 0xb8c -> 0xb8c after placement)
code   0x0fb050 ILLEGAL  TRIPWIRE for unresolved 0x494de
# code+0x1d22: unresolved 0x494de -> tripwire 0xfb050
# code+0x1f06: pcrel16 -> x057456@0x574bc (disp 0x926 -> 0x926 after placement)
# code+0x20de: pcrel16 -> x057456@0x574b0 (disp 0x742 -> 0x742 after placement)
# code+0x2192: pcrel16 -> x057456@0x574b0 (disp 0x68e -> 0x68e after placement)
# code+0x21aa: pcrel16 -> x057456@0x574b0 (disp 0x676 -> 0x676 after placement)
# code+0x2226: pcrel16 -> x057456@0x574b0 (disp 0x5fa -> 0x5fa after placement)
# code+0x2392: pcrel16 -> code@0x57024 (disp 0x2 -> 0x2 after placement)
# code+0x249c: pcrel16 -> x057456@0x574b0 (disp 0x384 -> 0x384 after placement)
# code+0x253c: pcrel16 -> x057456@0x574b0 (disp 0x2e4 -> 0x2e4 after placement)
# code+0x2546: pcrel16 -> code@0x571d8 (disp 0x2 -> 0x2 after placement)
# code+0x13bc: data_in_code reroute -> helper 0x3fad50, table 0x3fad40 (DATA view of vsav2 0x056074; FG capture-pose random table (native draws seqs 1/3/5))
# code+0x1390: data_in_code reroute -> helper 0x3fad70, table 0x3fad60 (DATA view of vsav2 0x056064; FG capture-pose table 2 (seqs 0x56-0x59))
# code+0x17c8: data_in_code reroute -> helper 0x3fad90, table 0x3fad80 (DATA view of vsav2 0x05649c; capture-pose table 3 (seqs 0x56-0x59 twin))
# code+0x17f4: data_in_code reroute -> helper 0x3fadb0, table 0x3fada0 (DATA view of vsav2 0x0564ac; capture-pose table 4 (01/03/05 twin))
code_file 0x0bf6a0 +0x27c6  donovan code (from vsav2 0x054C90)
data_file 0x0f7020 +0x32b2  donovan hitbox (from vsav2 0x0C4250)
data_file 0x0fa2e0 +0x3c6  donovan hitbox_proj (from vsav2 0x0D05C0)
code   0x0fb060 ILLEGAL  TRIPWIRE for unresolved 0x2cd38
# x022400+0x112: unresolved 0x2cd38 -> tripwire 0xfb060
# bank_ref 0xd8998 -> 0xbe7fa (delta rule, 16B byte-identical)
code   0x0fb070 ILLEGAL  TRIPWIRE for unresolved 0x7f5f4
# x022400+0xa82: unresolved 0x7f5f4 -> tripwire 0xfb070
code   0x0fb080 ILLEGAL  TRIPWIRE for unresolved 0x82480
# x022400+0xada: unresolved 0x82480 -> tripwire 0xfb080
# bank_ref 0xd9638 -> 0xbf49a (delta rule, known table base)
code   0x0fb090 ILLEGAL  TRIPWIRE for unresolved 0x828fe
# x022400+0xb66: unresolved 0x828fe -> tripwire 0xfb090
# bank_ref 0xd8998 -> 0xbe7fa (delta rule, 16B byte-identical)
code   0x0fb0a0 ILLEGAL  TRIPWIRE for unresolved 0xbdb0
# x022400+0x12ac: unresolved 0xbdb0 -> tripwire 0xfb0a0
# x022400+0x12fa: unresolved 0x2cd38 -> tripwire 0xfb060
code   0x0fb0b0 ILLEGAL  TRIPWIRE for unresolved 0x8278c
# x022400+0x14c0: unresolved 0x8278c -> tripwire 0xfb0b0
code   0x0fb0c0 ILLEGAL  TRIPWIRE for unresolved 0x7b368
# x022400+0x15c8: unresolved 0x7b368 -> tripwire 0xfb0c0
code   0x0fb0d0 ILLEGAL  TRIPWIRE for unresolved 0x3d1c
# x022400+0x662: unresolved 0x3d1c -> tripwire 0xfb0d0
code   0x0fb0e0 ILLEGAL  TRIPWIRE for unresolved 0x3dc6
# x022400+0x696: unresolved 0x3dc6 -> tripwire 0xfb0e0
code   0x0fb0f0 ILLEGAL  TRIPWIRE for unresolved 0x3e70
# x022400+0x80c: unresolved 0x3e70 -> tripwire 0xfb0f0
# x022400+0x86c: unresolved 0x3d1c -> tripwire 0xfb0d0
code   0x0fb100 ILLEGAL  TRIPWIRE for unresolved 0x3c44
# x022400+0x1078: unresolved 0x3c44 -> tripwire 0xfb100
code   0x0fb110 ILLEGAL  TRIPWIRE for unresolved 0x3cb0
# x022400+0x13a0: unresolved 0x3cb0 -> tripwire 0xfb110
code   0x0fb120 ILLEGAL  TRIPWIRE for unresolved 0x3a28
# x022400+0x13e0: unresolved 0x3a28 -> tripwire 0xfb120
# x022400+0x13ee: unresolved 0x3a28 -> tripwire 0xfb120
code   0x0fb130 ILLEGAL  TRIPWIRE for unresolved 0x3980
# x022400+0x1404: unresolved 0x3980 -> tripwire 0xfb130
code   0x0fb140 ILLEGAL  TRIPWIRE for unresolved 0x41be
# x022400+0x14ce: unresolved 0x41be -> tripwire 0xfb140
# x022400+0x82: char-id imm 0x10 -> 0x10
# x022400+0x1618: ESCAPE TRIPWIRE for unresolved pcrel target 0x24d12
# x022400+0x1624: ESCAPE TRIPWIRE for unresolved pcrel target 0x275e4
# pcrel_escape_fix x022400: 118 escapes -> 11 trampolines (2 tripwired), pad 0x1600..0x1780
code_file 0x0c7070 +0x1780  donovan x022400 (from vsav2 0x022400)
code   0x0fb150 ILLEGAL  TRIPWIRE for unresolved 0x2cbde
# x02592a+0x16e: unresolved 0x2cbde -> tripwire 0xfb150
code   0x0fb160 ILLEGAL  TRIPWIRE for unresolved 0x2ce0a
# x02592a+0x18a: unresolved 0x2ce0a -> tripwire 0xfb160
code   0x0fb170 ILLEGAL  TRIPWIRE for unresolved 0x2ce3e
# x02592a+0x368: unresolved 0x2ce3e -> tripwire 0xfb170
code   0x0fb180 ILLEGAL  TRIPWIRE for unresolved 0x364a
# x02592a+0x44a: unresolved 0x364a -> tripwire 0xfb180
# pcrel_escape_fix x02592a: 89 escapes -> 35 trampolines (0 tripwired), pad 0x456..0x576
code_file 0x0c87f0 +0x576  donovan x02592a (from vsav2 0x02592A)
# x026142+0x140e: bank table row 0x10 <- 0x1000 (bank 4, WIDE encoding; vanilla row was 0x1000) — tenant-driven
# x026142+0x13ee: table_fix 48 bytes (ported per-char OBJ bank table -> vanilla vsavj values + row 0x10 = WIDE bank 4)
# bank_ref 0xd7a18 -> 0xbd87a (delta rule, 16B byte-identical)
# bank_ref 0xd8358 -> 0xbe1ba (delta rule, 16B byte-identical)
# bank_ref 0xd8358 -> 0xbe1ba (delta rule, 16B byte-identical)
# bank_ref 0xd7798 -> 0xbd5fa (delta rule, known table base)
# bank_ref 0xd7798 -> 0xbd5fa (delta rule, known table base)
# bank_ref 0xd7798 -> 0xbd5fa (delta rule, known table base)
# bank_ref 0xd7798 -> 0xbd5fa (delta rule, known table base)
# bank_ref 0xd7798 -> 0xbd5fa (delta rule, known table base)
# bank_ref 0xd7d18 -> 0xbdb7a (delta rule, 16B byte-identical)
# bank_ref 0xd7698 -> 0xbd4fa (delta rule, known table base)
# bank_ref 0xd7718 -> 0xbd57a (delta rule, known table base)
# bank_ref 0xd83d8 -> 0xbe23a (delta rule, 16B byte-identical)
# bank_ref 0xd6e3e -> 0xbcca0 (delta rule, 16B byte-identical)
# bank_ref 0xd9438 -> 0xbf29a (delta rule, known table base)
# bank_ref 0xd8a38 -> 0xbe89a (delta rule, 16B byte-identical)
# bank_ref 0xd8df8 -> 0xbec5a (delta rule, 16B byte-identical)
# bank_ref 0xd7098 -> 0xbcefa (delta rule, known table base)
# bank_ref 0xd7118 -> 0xbcf7a (delta rule, known table base)
# bank_ref 0xd7018 -> 0xbce7a (delta rule, known table base)
# bank_ref 0xd95b8 -> 0xbf41a (delta rule, known table base)
# bank_ref 0xd7198 -> 0xbcffa (delta rule, known table base)
# bank_ref 0xd7018 -> 0xbce7a (delta rule, known table base)
# bank_ref 0xd7098 -> 0xbcefa (delta rule, known table base)
# bank_ref 0xd7118 -> 0xbcf7a (delta rule, known table base)
# bank_ref 0xd7198 -> 0xbcffa (delta rule, known table base)
# x026142+0x1dc: char-id imm 0x10 -> 0x10
# x026142+0x210: char-id imm 0x10 -> 0x10
# x026142+0xa22: char-id imm 0x10 -> 0x10
# x026142+0x1464: ESCAPE TRIPWIRE for unresolved pcrel target 0x2d532
# x026142+0x146a: ESCAPE TRIPWIRE for unresolved pcrel target 0x2b544
# x026142+0x1470: ESCAPE TRIPWIRE for unresolved pcrel target 0x2d548
# pcrel_escape_fix x026142: 12 escapes -> 9 trampolines (3 tripwired), pad 0x1440..0x14a0
code_file 0x0c8d70 +0x14a0  donovan x026142 (from vsav2 0x026142)
# bank_ref 0xd6ebe -> 0xbcd20 (delta rule, 16B byte-identical)
# bank_ref 0xd699e -> 0xbc800 (delta rule, 16B byte-identical)
# bank_ref 0xd671e -> 0xbc580 (delta rule, 16B byte-identical)
# bank_ref 0xd671e -> 0xbc580 (delta rule, 16B byte-identical)
# bank_ref 0xd679e -> 0xbc600 (delta rule, 16B byte-identical)
# bank_ref 0xd679e -> 0xbc600 (delta rule, 16B byte-identical)
# x028122+0x2f8: char-id imm 0x10 -> 0x10
# x028122+0x39c: char-id imm 0x10 -> 0x10
# x028122+0x488: char-id imm 0x10 -> 0x10
# x028122+0xc5a: char-id imm 0x10 -> 0x10
# x028122+0xdc6: char-id imm 0x10 -> 0x10
code_file 0x0ca210 +0xe00  donovan x028122 (from vsav2 0x028122)
code   0x0fb190 slot-clearing alloc wrapper for 0x1572e -> 0x16fe6 (0x80 cleared, +8 preserved)
code   0x0fb1d0 farm-port stub for 0x2915c (param at 0x0fb1c0, common 0x29f4a)
code   0x0fb1f0 farm-port stub for 0x29164 (param at 0x0fb1e0, common 0x29f4a)
code   0x0fb200 ILLEGAL  TRIPWIRE for unresolved 0x4223c
# x057456+0x3b42: unresolved 0x4223c -> tripwire 0xfb200
code   0x0fb210 ILLEGAL  TRIPWIRE for unresolved 0x42cee
# x057456+0x421a: unresolved 0x42cee -> tripwire 0xfb210
code   0x0fb220 ILLEGAL  TRIPWIRE for unresolved 0x448d4
# x057456+0x50cc: unresolved 0x448d4 -> tripwire 0xfb220
# x057456+0x418e: char-id imm 0x10 -> 0x10
# x057456+0x1f36: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H own zone): vs2 bank 3 -> WIDE bank 4)
code_file 0x0c1e66 +0x5200  donovan x057456 (from vsav2 0x057456)
code   0x0fb230 ILLEGAL  TRIPWIRE for unresolved 0x12f484
# x05c800+0x152a: unresolved 0x12f484 -> tripwire 0xfb230
# x05c800+0x16a4: unresolved 0x12f484 -> tripwire 0xfb230
code   0x0fb240 ILLEGAL  TRIPWIRE for unresolved 0x167bf4
# x05c800+0x2622: unresolved 0x167bf4 -> tripwire 0xfb240
# x05c800+0x2a20: unresolved 0x167bf4 -> tripwire 0xfb240
code   0x0fb250 ILLEGAL  TRIPWIRE for unresolved 0x17f176
# x05c800+0x2ae4: unresolved 0x17f176 -> tripwire 0xfb250
# x05c800+0x3034: unresolved 0x17f176 -> tripwire 0xfb250
code   0x0fb260 ILLEGAL  TRIPWIRE for unresolved 0x181592
# x05c800+0x3072: unresolved 0x181592 -> tripwire 0xfb260
# x05c800+0x1456: char-id imm 0x10 -> 0x10
# x05c800+0x738: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x05c800+0x58d4: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x05c800+0x5994: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# pcrel_escape_fix x05c800: 2 escapes -> 1 trampolines (0 tripwired), pad 0x6a00..0x6a20
code_file 0x0cb010 +0x6a20  donovan x05c800 (from vsav2 0x05C800)
code_file 0x0d1a30 +0x280  donovan x0672d0 (from vsav2 0x0672D0)
code_file 0x0d1cb0 +0x2f6  donovan x067550 (from vsav2 0x067550)
code_file 0x0d1fb0 +0x1ba  donovan x067846 (from vsav2 0x067846)
code_file 0x0d2170 +0x60c  donovan x067a00 (from vsav2 0x067A00)
# x06800c+0x354: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x396: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x3de: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x422: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
code_file 0x0d2780 +0x44c  donovan x06800c (from vsav2 0x06800C)
code_file 0x0d2bd0 +0x310  donovan x068458 (from vsav2 0x068458)
code_file 0x0d2ee0 +0x264  donovan x068768 (from vsav2 0x068768)
code_file 0x0d3150 +0x2ac  donovan x0689cc (from vsav2 0x0689CC)
code   0x0fb270 +0x40  patched clone of 0x5459a for vs2 0x5c77e (unmasked set-anim entry; false byte-matc)
code_file 0x0d3400 +0x3ce  donovan x068c78 (from vsav2 0x068C78)
code_file 0x0d37d0 +0x2b0  donovan x069046 (from vsav2 0x069046)
# x0692f6+0x19a: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
code_file 0x0d3a80 +0x368  donovan x0692f6 (from vsav2 0x0692F6)
code_file 0x0d3df0 +0x100  donovan x06965e (from vsav2 0x06965E)
code   0x0fb2b0 ILLEGAL  TRIPWIRE for unresolved 0x22f2d2
# x06cac0+0x546: unresolved 0x22f2d2 -> tripwire 0xfb2b0
code   0x0fb2c0 ILLEGAL  TRIPWIRE for unresolved 0x4cb0
# x06cac0+0x552: unresolved 0x4cb0 -> tripwire 0xfb2c0
code   0x0fb2d0 ILLEGAL  TRIPWIRE for unresolved 0x4c96
# x06cac0+0x586: unresolved 0x4c96 -> tripwire 0xfb2d0
# x06cac0+0x58e: unresolved 0x22f2d2 -> tripwire 0xfb2b0
# bank_ref 0xd7118 -> 0xbcf7a (delta rule, known table base)
# bank_ref 0xd7118 -> 0xbcf7a (delta rule, known table base)
code   0x0fb2e0 ILLEGAL  TRIPWIRE for unresolved 0x3a90
# x06cac0+0xacc: unresolved 0x3a90 -> tripwire 0xfb2e0
code   0x0fb2f0 ILLEGAL  TRIPWIRE for unresolved 0x3a76
# x06cac0+0xb18: unresolved 0x3a76 -> tripwire 0xfb2f0
# x06cac0+0xb60: unresolved 0x3a76 -> tripwire 0xfb2f0
# x06cac0+0xbac: unresolved 0x3a76 -> tripwire 0xfb2f0
# pcrel_escape_fix x06cac0: 0 escapes -> 0 trampolines (0 tripwired), pad 0xc00..0xc60
code_file 0x0d3ef0 +0xc60  donovan x06cac0 (from vsav2 0x06CAC0)
code   0x0fb300 ILLEGAL  TRIPWIRE for unresolved 0x281696
# x088512+0x348: unresolved 0x281696 -> tripwire 0xfb300
code   0x0fb310 ILLEGAL  TRIPWIRE for unresolved 0x289b14
# x088512+0x126a: unresolved 0x289b14 -> tripwire 0xfb310
# x088512+0x127c: unresolved 0x289b14 -> tripwire 0xfb310
code   0x0fb320 ILLEGAL  TRIPWIRE for unresolved 0x28ed08
# x088512+0x1de2: unresolved 0x28ed08 -> tripwire 0xfb320
code   0x0fb330 ILLEGAL  TRIPWIRE for unresolved 0x36784a
# x088512+0x1dee: unresolved 0x36784a -> tripwire 0xfb330
code   0x0fb340 ILLEGAL  TRIPWIRE for unresolved 0x2695d0
# x088512+0x2894: unresolved 0x2695d0 -> tripwire 0xfb340
code   0x0fb350 ILLEGAL  TRIPWIRE for unresolved 0x2abd58
# x088512+0x359c: unresolved 0x2abd58 -> tripwire 0xfb350
# x088512+0x2be6: port_patch 000e -> 000c (companion queue class 7 (vs2-only) -> vsavj class 6 (the Anita precedent))
# x088512+0x22c: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x088512+0x1814: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x088512+0x2bee: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x088512+0x2d12: port_patch 3d7c20000018 -> 3d7c30000018 (companion-piece bank setter: effect page bank 1 -> WIDE bank 5 (native codes))
# x088512+0x3a02: port_patch 397c20000018 -> 397c30000018 (companion-piece bank setter: effect page bank 1 -> WIDE bank 5 (native codes))
# x088512+0x3a40: port_patch 397c20000018 -> 397c30000018 (companion-piece bank setter: effect page bank 1 -> WIDE bank 5 (native codes))
# x088512+0x3ae4: data_in_code reroute -> helper 0x3faec0, table 0x3fadc0 (DATA view of vsav2 0x08c042; pod-zone word offset/record table (a3 re-derived from it; self-relative))
code_file 0x0d4b50 +0x3b40  donovan x088512 (from vsav2 0x088512)
data_file 0x0fa6b0 +0x900  donovan x0d143e (from vsav2 0x0D143E)
code   0x0fb360 ILLEGAL  TRIPWIRE for unresolved 0x2c31aa
# x2b7ef4+0xb0d9: unresolved 0x2c31aa -> tripwire 0xfb360
code   0x0fb370 ILLEGAL  TRIPWIRE for unresolved 0x2c31e4
# x2b7ef4+0xb0fd: unresolved 0x2c31e4 -> tripwire 0xfb370
code   0x0fb380 ILLEGAL  TRIPWIRE for unresolved 0x2c3236
# x2b7ef4+0xb105: unresolved 0x2c3236 -> tripwire 0xfb380
code   0x0fb390 ILLEGAL  TRIPWIRE for unresolved 0x2c325c
# x2b7ef4+0xb10d: unresolved 0x2c325c -> tripwire 0xfb390
code   0x0fb3a0 ILLEGAL  TRIPWIRE for unresolved 0x2c3272
# x2b7ef4+0xb115: unresolved 0x2c3272 -> tripwire 0xfb3a0
code   0x0fb3b0 ILLEGAL  TRIPWIRE for unresolved 0x2c3280
# x2b7ef4+0xb11d: unresolved 0x2c3280 -> tripwire 0xfb3b0
code   0x0fb3c0 ILLEGAL  TRIPWIRE for unresolved 0x2c3296
# x2b7ef4+0xb125: unresolved 0x2c3296 -> tripwire 0xfb3c0
code   0x0fb3d0 ILLEGAL  TRIPWIRE for unresolved 0x2c32a4
# x2b7ef4+0xb12d: unresolved 0x2c32a4 -> tripwire 0xfb3d0
code   0x0fb3e0 ILLEGAL  TRIPWIRE for unresolved 0x2c32b2
# x2b7ef4+0xb135: unresolved 0x2c32b2 -> tripwire 0xfb3e0
# x2b7ef4: effect-c5 — 5714 bank-1 codes kept NATIVE (art -> group C bank 5); 114 coord lists matched, 617 ported (11336B fragment)
data_file 0x400010 +0xb20c  donovan x2b7ef4 (from vsav2 0x2B7EF4)
data     0x3fdb20 +0x500  sprite palette block (vsav2 0x39BC9C); poke32 0x38c1d8 (table 0x38c198 row 0x10)
data     0x0fb3f0 +0xdc0  effect palette block (vsav2 0x3AB69C); poke32 0x38c258 (table 0x38c218 row 0x10)
poke32 0x0bceba <- 0x000d8690  anim_index_a[0x10] donovan anim
poke32 0x0bcf3a <- 0x000dd1ec  anim_index_a2[0x10] donovan anim
poke32 0x0bcfba <- 0x000dacfa  anim_index_b[0x10] donovan anim
poke32 0x0bd03a <- 0x000dac84  anim_index_c[0x10] donovan anim
poke32 0x0bd0ba <- 0x000e2cf4  anim_index_proj[0x10] donovan anim
data   0x0bd8fa +0x8  param32_a[0x10] value
data   0x0bde7a +0x30  jump_params[0x10] value
poke32 0x0bd9ba <- 0x000f7140  hitbox_base[0x10] donovan hitbox
poke32 0x0bda3a <- 0x000f7020  hitbox_comp[0x10] donovan hitbox
poke32 0x0bdaba <- 0x000fa314  proj_hitbox_base[0x10] donovan hitbox_proj
poke32 0x0bdb3a <- 0x000fa2e0  proj_hitbox_comp[0x10] donovan hitbox_proj
data   0x0bdbfa +0x8  rec8_a[0x10] value
data   0x0be19a +0x2  word132[0x10] value
data   0x0be1da +0x2  word_pos_a[0x10] value
data   0x0be21a +0x2  word_pos_b[0x10] value
data   0x0be37a +0x8  param32_b[0x10] value
data   0x0be47a +0x8  rec8_b[0x10] value
data   0x0be81a +0x2  word_y_off[0x10] value
data   0x0be85a +0x2  word_range[0x10] value
data   0x0be88a +0x2  byte15b[0x10] value
data   0x0bea7a +0x1e  byte2d_a[0x10] value
data   0x0bee3a +0x1e  byte2d_b[0x10] value
poke32 0x0bf2da <- 0x000bfe88  tail_code_ptr[0x10] donovan code
poke32 0x0bf45a <- 0x000fa1fa  tail_data_ptr[0x10] donovan hitbox
poke32 0x0bd4ba <- 0x00024ea4  dispatch_07[0x10] engine twin of 0x23afe (alias char row 0x2d68e differs)
code   0x0fc1b0 ILLEGAL  TRIPWIRE for unresolved 0x65c22
# obj_hook@0x54470 type 59: unresolved 0x65c22 -> tripwire 0xfc1b0
code   0x0fc1c0 ILLEGAL  TRIPWIRE for unresolved 0x65e5a
# obj_hook@0x54470 type 60: unresolved 0x65e5a -> tripwire 0xfc1c0
# obj_hook@0x54470 type 61: unresolved 0x65e5a -> tripwire 0xfc1c0
code   0x0fc1d0 ILLEGAL  TRIPWIRE for unresolved 0x66ec4
# obj_hook@0x54470 type 62: unresolved 0x66ec4 -> tripwire 0xfc1d0
code   0x0fc1e0 ILLEGAL  TRIPWIRE for unresolved 0x6717c
# obj_hook@0x54470 type 63: unresolved 0x6717c -> tripwire 0xfc1e0
data   0x0fc1f0 +0x130  proj_hook extended type table (59 vanilla + 17 ported, 12 placed)
code   0x0fc320 obj_hook thunk (ghost-clean: returns to vanilla jsr)
code   0x054470 ENGINE HOOK: dispatch -> jmp thunk; vanilla jsr (A0) at 0x54476 untouched (vanilla types identical via table copy)
code   0x0fc340 ILLEGAL  TRIPWIRE for unresolved 0x6a70c
# obj_hook@0x5e542 type 121: unresolved 0x6a70c -> tripwire 0xfc340
# obj_hook@0x5e542 type 122: unresolved 0x6a70c -> tripwire 0xfc340
# obj_hook@0x5e542 type 123: unresolved 0x6a70c -> tripwire 0xfc340
data   0x0fc350 +0x1f0  proj_hook extended type table (114 vanilla + 10 ported, 7 placed)
code   0x0fc540 obj_hook thunk (ghost-clean: returns to vanilla jsr)
code   0x05e542 ENGINE HOOK: dispatch -> jmp thunk; vanilla jsr (A0) at 0x5e548 untouched (vanilla types identical via table copy)
code   0x0fc560 init shim (pool latch A5+0x7966, seeder 0x16c64; flavor (A6+0x3c2)<-0x00, Start-held [0xff8060 bit=player] -> 0x01) -> handler 0x0c1e60
poke32 0x0bd13a <- 0x000fc560  dispatch_00[0x10] donovan handler via seed shim
poke32 0x0bd1ba <- 0x000bf6ac  dispatch_01[0x10] donovan handler
poke32 0x0bd23a <- 0x000bff70  dispatch_02[0x10] donovan handler
poke32 0x0bd2ba <- 0x000bff70  dispatch_03[0x10] donovan handler
poke32 0x0bd33a <- 0x000bff70  dispatch_04[0x10] donovan handler
poke32 0x0bd3ba <- 0x000c1794  dispatch_05[0x10] donovan handler
poke32 0x0bd43a <- 0x000bf8c6  dispatch_06[0x10] donovan handler
poke32 0x0bd53a <- 0x000bfaf2  dispatch_08[0x10] donovan handler
poke32 0x0bd5ba <- 0x000bfc3e  dispatch_09[0x10] donovan handler
poke32 0x0bd63a <- 0x000bf852  dispatch_10[0x10] donovan handler
poke32 0x0bd6ba <- 0x000c1be4  dispatch_11[0x10] donovan handler
poke32 0x0bd73a <- 0x000c1e00  dispatch_12[0x10] donovan handler
poke32 0x0bd7ba <- 0x000c1e30  dispatch_13[0x10] donovan handler
poke32 0x0bd83a <- 0x000c1a30  dispatch_14[0x10] donovan handler
poke32 0x0bf25a <- 0x000bfb16  dispatch_15[0x10] donovan handler
poke32 0x0bf35a <- 0x000c168a  dispatch_16[0x10] donovan handler
poke32 0x0bf3da <- 0x000c1778  dispatch_17[0x10] donovan handler
poke32 0x0bf4da <- 0x000c1e9a  dispatch_18[0x10] donovan handler
poke32 0x0bf65a <- 0x000c1780  dispatch_19[0x10] donovan handler
poke16 0x0898a4 <- 0x869a  aux hud_mug_entry_10
poke32 0x089944 <- 0x86920102  aux hud_name_entry_10_hi
poke32 0x089948 <- 0xffe80002  aux hud_name_entry_10_lo
poke16 0x028d4e <- 0xf1b  aux effect_map_4e4f
poke16 0x028d50 <- 0x1f19  aux effect_map_5051
poke16 0x028d52 <- 0xf03  aux effect_map_5253
data   0x0211e4        select_wheel roster21: TABLE B in place, 28 bytes over 3 new rows + 5 inbound edges
data   0x40b220 +0x54  select_wheel roster21 coord list (18 vanilla + 3 new)
data   0x40b280 +0x5e  select_wheel roster21 record (count 17->20, budget 0x55 CARRIED OVER, cptr -> 0x40b220)
poke32 0x2689fe <- 0x40b280  select_wheel roster21 record ptr (was 0x272a68; the record's ONLY referrer — vanilla record and list are untouched)
code   0x05fb22 +4     select_wheel roster21: highlight base row 0x10 <- (158,80) (was the row 0x00 alias)
code   0x05fb26 +4     select_wheel roster21: highlight base row 0x11 <- (188,72) (was the row 0x01 alias)
code   0x05fb2e +4     select_wheel roster21: highlight base row 0x13 <- (216,80) (was the row 0x03 alias)
# select_wheel roster21: 3 highlight base rows written in place (32-row aliased pc-rel table 0x5fae2; the vs2 precedent — its variant half is un-aliased for its newcomers)
poke32 0x268a46 <- 0x2724a2  select_wheel roster21: p1 highlight row 0x11 = host row 0x0f ring (ring_rows)
poke32 0x268a4e <- 0x2724a2  select_wheel roster21: p1 highlight row 0x13 = host row 0x0f ring (ring_rows)
poke32 0x268ac6 <- 0x2726ce  select_wheel roster21: p2 highlight row 0x11 = host row 0x0f ring (ring_rows)
poke32 0x268ace <- 0x2726ce  select_wheel roster21: p2 highlight row 0x13 = host row 0x0f ring (ring_rows)
poke32 0x268b42 <- 0x2728e6  select_wheel roster21: mirror highlight row 0x10 = host row 0x0f ring (ring_rows)
poke32 0x268b46 <- 0x2728e6  select_wheel roster21: mirror highlight row 0x11 = host row 0x0f ring (ring_rows)
poke32 0x268b4e <- 0x2728e6  select_wheel roster21: mirror highlight row 0x13 = host row 0x0f ring (ring_rows)
# select_wheel roster21: 7 ring rows poked (host row 0x0f records verbatim; P1/P2 for non-tenant cells + mirror for all)
code   0x05f8b2 +6     select_wheel roster21: drawer bank word #$2000 -> #$3000 (bank 5) in the select init — writes ONLY $FFB818 (measured)
# select_wheel roster21: 85 host + 18 vs2 tiles -> wheel_bank5.json (group C upper bank, placed by build_gfx --wheel-bank5)
data   0x3a3b20 +0x20  select_wheel roster21: medallion pal row 0x19 (cell 0x10) <- vs2 0x3bb19c; entry attr re-palmed
data   0x3a3b40 +0x20  select_wheel roster21: medallion pal row 0x1a (cell 0x11) <- vs2 0x3bb15c; entry attr re-palmed
data   0x3a3ac0 +0x20  select_wheel roster21: medallion pal row 0x16 (cell 0x13) <- vs2 0x3bafdc; entry attr re-palmed
code   0x0fc5b0 +0x28  select_wheel roster21: march mid-row retarget 0x16/0x19 -> 0x02 (dest computation 0x2b598 jsr-routed)
code   0x0fc5e0 +0x28  select_wheel roster21: march mid-row retarget 0x16/0x19 -> 0x02 (dest computation 0x2b7d8 jsr-routed)
data   0x40b2e0 +0x1c  select_records portrait/p1 coord list (7 pairs, vs2 0x303238)
data   0x40b300 +0x26  select_records portrait/p1 record (vs2 0x2a5e4a, 7 entries, budget 0x5b = vs2's own)
poke32 0x26746a <- 0x40b300  select_records portrait/p1 array row 0x10 (was 0x271924, the base-half alias)
data   0x40b330 +0x1c  select_records portrait/p2 coord list (7 pairs, vs2 0x3035a8)
data   0x40b350 +0x26  select_records portrait/p2 record (vs2 0x2a625a, 7 entries, budget 0x5b = vs2's own)
poke32 0x2674ea <- 0x40b350  select_records portrait/p2 array row 0x10 (was 0x271d36, the base-half alias)
data   0x40b380 +0x4  select_records name_banner/p1 coord list (1 pairs, vs2 0x303730)
data   0x40b390 +0xe  select_records name_banner/p1 record (vs2 0x2a64d6, 1 entries, budget 0x8 = vs2's own)
poke32 0x2675ea <- 0x40b390  select_records name_banner/p1 array row 0x10 (was 0x272148, the base-half alias)
data   0x40b3a0 +0x8  select_records name_banner/p2 coord list (2 pairs, vs2 0x303d9c)
data   0x40b3b0 +0x12  select_records name_banner/p2 record (vs2 0x2a7506, 2 entries, budget 0x3 = vs2's own)
poke32 0x26766a <- 0x40b3b0  select_records name_banner/p2 array row 0x10 (was 0x273052, the base-half alias)
data   0x40b3d0 +0x14  select_records splash_p1/p1 coord list (5 pairs, vs2 0x304028)
data   0x40b3f0 +0x1e  select_records splash_p1/p1 record (vs2 0x2a7b06, 5 entries, budget 0x4c = vs2's own)
poke32 0x2672ea <- 0x40b3f0  select_records splash_p1/p1 array row 0x10 (was 0x273462, the base-half alias)
data   0x40b410 +0x14  select_records splash_p2/p1 coord list (5 pairs, vs2 0x3042b8)
data   0x40b430 +0x1e  select_records splash_p2/p1 record (vs2 0x2a7e36, 5 entries, budget 0x4c = vs2's own)
poke32 0x26736a <- 0x40b430  select_records splash_p2/p1 array row 0x10 (was 0x2737a8, the base-half alias)
data   0x40b450 +0x84  select_records win_quote/p1 coord list (33 pairs, vs2 0x304bd8)
data   0x40b4e0 +0x8e  select_records win_quote/p1 record (vs2 0x2a881e, 33 entries, budget 0x8a = vs2's own)
poke32 0x2673ea <- 0x40b4e0  select_records win_quote/p1 array row 0x10 (was 0x273aee, the base-half alias)
poke32 0x268a42 <- 0x2724a2  select_records highlight/p1 array row 0x10 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x272554)
poke32 0x268ac2 <- 0x2726ce  select_records highlight/p2 array row 0x10 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x272780)
# select_records: 0 bank-1 tile placements -> select_tiles.json (only the composed records' art; the slot-0x0F splash/win-quote families are NOT placed, so that Jedah art stays vanilla)
# select_records: 236 native bank-1 tiles -> select_bank5.json (copied vs2 -> group C bank 5 by build_gfx; the drawer's bank is thunk-gated per hover)
data   0x40b570 +0x4b00  win_pal_variant hui_win_pal: sparse block, 8 sets of 0xa0 at stride 0xaa0 (vs2 0x3c329c stride 0xb40)
code   0x0fc610 +0x16  win_pal_variant hui_win_pal thunk (d6==TT -> a0 = 0x40ab70; else vanilla pool 0x3ad700)
code   0x05f1b6 +6     win_pal_variant hui_win_pal: movea.l #pool -> jsr 0xfc610
code   0x0fc630 +0x1a  site_thunk tenant_jump_seq; site 0x022a0e jmp-routed
code   0x0fc650 +0xe  site_thunk shadow_seq_guard; site 0x08245c jmp-routed
code   0x0fc660 +0x1e  site_thunk name_bank_variant_id; site 0x05fce0 jsr-routed
code   0x0fc680 +0x1e  site_thunk splash_bank_variant_id; site 0x06c0e0 jsr-routed
code   0x0fc6a0 +0x16  site_thunk winquote_bank_variant_id; site 0x05f328 jsr-routed
data   0x410070 +0x140  site_thunk select_pal_variant_id data block <- vsav2 0x3c12dc
code   0x0fc6c0 +0x38  site_thunk select_pal_variant_id; site 0x05f146 jsr-routed
data   0x4101b0 +0x54  site_thunk throw_arc_tables data block <- vsav2 0x0279b4
data   0x410210 +0x370  site_thunk throw_arc_tables data block <- vsav2 0x027a08
code   0x0fc700 +0x42  site_thunk throw_arc_tables; site 0x028386 jmp-routed
code   0x0fc750 +0xe  site_thunk idmask_victim_spawn; site 0x060ef0 jmp-routed
code   0x0fc760 +0x10  site_thunk idmask_piece_subtype; site 0x05e7d6 jmp-routed
code   0x0282f4 +0x2  code_word obj_bank_word_slot (slot entry -> 1000)
code   0x05f240 +0x2  code_word win_pos_x_slot (slot entry -> 00c0)
code   0x05f242 +0x2  code_word win_pos_y_slot (slot entry -> 0080)
# image: extend to 0x600000 (4 x 0x80000 member(s): vsw.41, vsw.42, vsw.43, vsw.44)
