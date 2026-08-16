# donovan-m2 stage 6 — generated op notes

# stage 1: Jedah hitbox block 0x091E58+0x0 (base 0x91f98 comp 0x91e58)
# table_fix: region x026142 len 0x1400 -> 0x1440 (ported per-char OBJ bank table -> vanilla vsavj values + row 0x10 = WIDE bank 4)
# layout group at 0xbf6a0+0x79c6: code@0xbf6a0, x057456@0xc1e66; 0x0 gap bytes recycled
# anim+0x4ed2: port_patch 000c -> 0006 (composite list 24A744: list-type 12 -> the taken-over type 6)
# anim+0x557a: port_patch 000c -> 0006 (composite list 24ADEC: list-type 12 -> the taken-over type 6)
# anim+0x575a: port_patch 000c -> 0006 (composite list 24AFCC: list-type 12 -> the taken-over type 6)
# anim+0x584a: port_patch 000c -> 0006 (composite list 24B0BC: list-type 12 -> the taken-over type 6)
# anim+0x90f6: port_patch 000c -> 0006 (composite list 24E968: list-type 12 -> the taken-over type 6)
# anim+0x910e: port_patch 000c -> 0006 (composite list 24E980: list-type 12 -> the taken-over type 6)
# anim+0x9126: port_patch 000c -> 0006 (composite list 24E998: list-type 12 -> the taken-over type 6)
# anim+0x913e: port_patch 000c -> 0006 (composite list 24E9B0: list-type 12 -> the taken-over type 6)
# anim+0x9156: port_patch 000c -> 0006 (composite list 24E9C8: list-type 12 -> the taken-over type 6)
# anim+0x916e: port_patch 000c -> 0006 (composite list 24E9E0: list-type 12 -> the taken-over type 6)
# anim+0x9186: port_patch 000c -> 0006 (composite list 24E9F8: list-type 12 -> the taken-over type 6)
# anim+0x919e: port_patch 000c -> 0006 (composite list 24EA10: list-type 12 -> the taken-over type 6)
# anim+0x91b6: port_patch 000c -> 0006 (composite list 24EA28: list-type 12 -> the taken-over type 6)
# anim+0xc460: port_patch 000c -> 0006 (composite list 251CD2: list-type 12 -> the taken-over type 6)
# anim+0xc474: port_patch 000c -> 0006 (composite list 251CE6: list-type 12 -> the taken-over type 6)
# anim+0xc490: port_patch 000c -> 0006 (composite list 251D02: list-type 12 -> the taken-over type 6)
# anim+0xc4ac: port_patch 000c -> 0006 (composite list 251D1E: list-type 12 -> the taken-over type 6)
# anim+0xc4c8: port_patch 000c -> 0006 (composite list 251D3A: list-type 12 -> the taken-over type 6)
# anim+0xc4e4: port_patch 000c -> 0006 (composite list 251D56: list-type 12 -> the taken-over type 6)
# anim+0xc500: port_patch 000c -> 0006 (composite list 251D72: list-type 12 -> the taken-over type 6)
# anim+0xc51c: port_patch 000c -> 0006 (composite list 251D8E: list-type 12 -> the taken-over type 6)
# anim+0xc538: port_patch 000c -> 0006 (composite list 251DAA: list-type 12 -> the taken-over type 6)
# anim+0xc554: port_patch 000c -> 0006 (composite list 251DC6: list-type 12 -> the taken-over type 6)
# anim+0xc570: port_patch 000c -> 0006 (composite list 251DE2: list-type 12 -> the taken-over type 6)
# anim+0xc58c: port_patch 000c -> 0006 (composite list 251DFE: list-type 12 -> the taken-over type 6)
# anim+0xc5a0: port_patch 000c -> 0006 (composite list 251E12: list-type 12 -> the taken-over type 6)
# anim+0xc5b4: port_patch 000c -> 0006 (composite list 251E26: list-type 12 -> the taken-over type 6)
# anim+0xc5d0: port_patch 000c -> 0006 (composite list 251E42: list-type 12 -> the taken-over type 6)
# anim+0xc5e4: port_patch 000c -> 0006 (composite list 251E56: list-type 12 -> the taken-over type 6)
# anim+0xc600: port_patch 000c -> 0006 (composite list 251E72: list-type 12 -> the taken-over type 6)
# anim+0xc61c: port_patch 000c -> 0006 (composite list 251E8E: list-type 12 -> the taken-over type 6)
# anim+0xc638: port_patch 000c -> 0006 (composite list 251EAA: list-type 12 -> the taken-over type 6)
# anim+0xc654: port_patch 000c -> 0006 (composite list 251EC6: list-type 12 -> the taken-over type 6)
# anim+0xc670: port_patch 000c -> 0006 (composite list 251EE2: list-type 12 -> the taken-over type 6)
# anim+0xc68c: port_patch 000c -> 0006 (composite list 251EFE: list-type 12 -> the taken-over type 6)
# anim+0xc6a8: port_patch 000c -> 0006 (composite list 251F1A: list-type 12 -> the taken-over type 6)
# anim+0xc6bc: port_patch 000c -> 0006 (composite list 251F2E: list-type 12 -> the taken-over type 6)
# anim+0xc6d0: port_patch 000c -> 0006 (composite list 251F42: list-type 12 -> the taken-over type 6)
# anim+0xc6e4: port_patch 000c -> 0006 (composite list 251F56: list-type 12 -> the taken-over type 6)
data_file 0x0d8cc0 +0x1e800  donovan anim (from vsav2 0x245872)
data_file 0x0f74c0 +0x190  donovan aux0_0 (from vsav2 0x334170)
data_file 0x3ec720 +0xe620  donovan aux0_1 (from vsav2 0x336560)
# code+0x9c: pcrel16 -> x057456@0x574b0 (disp 0x2784 -> 0x2784 after placement)
# code+0x102: pcrel16 -> x057456@0x574b0 (disp 0x271e -> 0x271e after placement)
# code+0x15a: pcrel16 -> x057456@0x574b6 (disp 0x26cc -> 0x26cc after placement)
# code+0x1a4: pcrel16 -> x057456@0x574b6 (disp 0x2682 -> 0x2682 after placement)
# code+0x2f4: pcrel16 -> x057456@0x574b0 (disp 0x252c -> 0x252c after placement)
code   0x0fb600 farm-port stub for 0x2916c (param at 0x0fb5e0, common 0x29f4a)
code   0x0fb620 farm-port stub for 0x29184 (param at 0x0fb610, common 0x29f4a)
code   0x0fb640 farm-port stub for 0x2918c (param at 0x0fb630, common 0x29f4a)
code   0x0fb650 slot-clearing alloc wrapper for 0x15702 -> 0x16fba (0x80 cleared, +8 preserved)
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
code   0x0fb680 ILLEGAL  TRIPWIRE for unresolved 0x494de
# code+0x1d22: unresolved 0x494de -> tripwire 0xfb680
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
data_file 0x0f7650 +0x32b2  donovan hitbox (from vsav2 0x0C4250)
data_file 0x0fa910 +0x3c6  donovan hitbox_proj (from vsav2 0x0D05C0)
code   0x0fb690 ILLEGAL  TRIPWIRE for unresolved 0x2cd38
# x022400+0x112: unresolved 0x2cd38 -> tripwire 0xfb690
# bank_ref 0xd8998 -> 0xbe7fa (delta rule, 16B byte-identical)
code   0x0fb6a0 ILLEGAL  TRIPWIRE for unresolved 0x7f5f4
# x022400+0xa82: unresolved 0x7f5f4 -> tripwire 0xfb6a0
code   0x0fb6b0 ILLEGAL  TRIPWIRE for unresolved 0x82480
# x022400+0xada: unresolved 0x82480 -> tripwire 0xfb6b0
# bank_ref 0xd9638 -> 0xbf49a (delta rule, known table base)
code   0x0fb6c0 ILLEGAL  TRIPWIRE for unresolved 0x828fe
# x022400+0xb66: unresolved 0x828fe -> tripwire 0xfb6c0
# bank_ref 0xd8998 -> 0xbe7fa (delta rule, 16B byte-identical)
code   0x0fb6d0 ILLEGAL  TRIPWIRE for unresolved 0xbdb0
# x022400+0x12ac: unresolved 0xbdb0 -> tripwire 0xfb6d0
# x022400+0x12fa: unresolved 0x2cd38 -> tripwire 0xfb690
code   0x0fb6e0 ILLEGAL  TRIPWIRE for unresolved 0x8278c
# x022400+0x14c0: unresolved 0x8278c -> tripwire 0xfb6e0
code   0x0fb6f0 ILLEGAL  TRIPWIRE for unresolved 0x7b368
# x022400+0x15c8: unresolved 0x7b368 -> tripwire 0xfb6f0
code   0x0fb700 ILLEGAL  TRIPWIRE for unresolved 0x3d1c
# x022400+0x662: unresolved 0x3d1c -> tripwire 0xfb700
code   0x0fb710 ILLEGAL  TRIPWIRE for unresolved 0x3dc6
# x022400+0x696: unresolved 0x3dc6 -> tripwire 0xfb710
code   0x0fb720 ILLEGAL  TRIPWIRE for unresolved 0x3e70
# x022400+0x80c: unresolved 0x3e70 -> tripwire 0xfb720
# x022400+0x86c: unresolved 0x3d1c -> tripwire 0xfb700
code   0x0fb730 ILLEGAL  TRIPWIRE for unresolved 0x3c44
# x022400+0x1078: unresolved 0x3c44 -> tripwire 0xfb730
code   0x0fb740 ILLEGAL  TRIPWIRE for unresolved 0x3cb0
# x022400+0x13a0: unresolved 0x3cb0 -> tripwire 0xfb740
code   0x0fb750 ILLEGAL  TRIPWIRE for unresolved 0x3a28
# x022400+0x13e0: unresolved 0x3a28 -> tripwire 0xfb750
# x022400+0x13ee: unresolved 0x3a28 -> tripwire 0xfb750
code   0x0fb760 ILLEGAL  TRIPWIRE for unresolved 0x3980
# x022400+0x1404: unresolved 0x3980 -> tripwire 0xfb760
code   0x0fb770 ILLEGAL  TRIPWIRE for unresolved 0x41be
# x022400+0x14ce: unresolved 0x41be -> tripwire 0xfb770
# x022400+0x82: char-id imm 0x10 -> 0x10
# x022400+0x1618: ESCAPE TRIPWIRE for unresolved pcrel target 0x24d12
# x022400+0x1624: ESCAPE TRIPWIRE for unresolved pcrel target 0x275e4
# pcrel_escape_fix x022400: 118 escapes -> 11 trampolines (2 tripwired), pad 0x1600..0x1780
code_file 0x0c7070 +0x1780  donovan x022400 (from vsav2 0x022400)
code   0x0fb780 ILLEGAL  TRIPWIRE for unresolved 0x2cbde
# x02592a+0x16e: unresolved 0x2cbde -> tripwire 0xfb780
code   0x0fb790 ILLEGAL  TRIPWIRE for unresolved 0x2ce0a
# x02592a+0x18a: unresolved 0x2ce0a -> tripwire 0xfb790
code   0x0fb7a0 ILLEGAL  TRIPWIRE for unresolved 0x2ce3e
# x02592a+0x368: unresolved 0x2ce3e -> tripwire 0xfb7a0
code   0x0fb7b0 ILLEGAL  TRIPWIRE for unresolved 0x364a
# x02592a+0x44a: unresolved 0x364a -> tripwire 0xfb7b0
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
# pcrel_escape_fix x026142: 9 escapes -> 6 trampolines (0 tripwired), pad 0x1440..0x14a0
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
code   0x0fb7c0 slot-clearing alloc wrapper for 0x1572e -> 0x16fe6 (0x80 cleared, +8 preserved)
code   0x0fb800 farm-port stub for 0x2915c (param at 0x0fb7f0, common 0x29f4a)
code   0x0fb820 farm-port stub for 0x29164 (param at 0x0fb810, common 0x29f4a)
code   0x0fb830 ILLEGAL  TRIPWIRE for unresolved 0x4223c
# x057456+0x3b42: unresolved 0x4223c -> tripwire 0xfb830
code   0x0fb840 ILLEGAL  TRIPWIRE for unresolved 0x42cee
# x057456+0x421a: unresolved 0x42cee -> tripwire 0xfb840
code   0x0fb850 ILLEGAL  TRIPWIRE for unresolved 0x448d4
# x057456+0x50cc: unresolved 0x448d4 -> tripwire 0xfb850
# x057456+0x418e: char-id imm 0x10 -> 0x10
# x057456+0x1f36: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H own zone): vs2 bank 3 -> WIDE bank 4)
code_file 0x0c1e66 +0x5200  donovan x057456 (from vsav2 0x057456)
code   0x0fb860 ILLEGAL  TRIPWIRE for unresolved 0x12f484
# x05c800+0x152a: unresolved 0x12f484 -> tripwire 0xfb860
# x05c800+0x16a4: unresolved 0x12f484 -> tripwire 0xfb860
code   0x0fb870 ILLEGAL  TRIPWIRE for unresolved 0x167bf4
# x05c800+0x2622: unresolved 0x167bf4 -> tripwire 0xfb870
# x05c800+0x2a20: unresolved 0x167bf4 -> tripwire 0xfb870
code   0x0fb880 ILLEGAL  TRIPWIRE for unresolved 0x17f176
# x05c800+0x2ae4: unresolved 0x17f176 -> tripwire 0xfb880
# x05c800+0x3034: unresolved 0x17f176 -> tripwire 0xfb880
code   0x0fb890 ILLEGAL  TRIPWIRE for unresolved 0x181592
# x05c800+0x3072: unresolved 0x181592 -> tripwire 0xfb890
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
code   0x0fb8a0 +0x40  patched clone of 0x5459a for vs2 0x5c77e (unmasked set-anim entry; false byte-matc)
code_file 0x0d3400 +0x3ce  donovan x068c78 (from vsav2 0x068C78)
code_file 0x0d37d0 +0x2b0  donovan x069046 (from vsav2 0x069046)
# x0692f6+0x19a: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
code_file 0x0d3a80 +0x368  donovan x0692f6 (from vsav2 0x0692F6)
code_file 0x0d3df0 +0x100  donovan x06965e (from vsav2 0x06965E)
code   0x0fb8e0 ILLEGAL  TRIPWIRE for unresolved 0x22f2d2
# x06cac0+0x546: unresolved 0x22f2d2 -> tripwire 0xfb8e0
code   0x0fb8f0 ILLEGAL  TRIPWIRE for unresolved 0x4cb0
# x06cac0+0x552: unresolved 0x4cb0 -> tripwire 0xfb8f0
code   0x0fb900 ILLEGAL  TRIPWIRE for unresolved 0x4c96
# x06cac0+0x586: unresolved 0x4c96 -> tripwire 0xfb900
# x06cac0+0x58e: unresolved 0x22f2d2 -> tripwire 0xfb8e0
# bank_ref 0xd7118 -> 0xbcf7a (delta rule, known table base)
# bank_ref 0xd7118 -> 0xbcf7a (delta rule, known table base)
code   0x0fb910 ILLEGAL  TRIPWIRE for unresolved 0x3a90
# x06cac0+0xacc: unresolved 0x3a90 -> tripwire 0xfb910
code   0x0fb920 ILLEGAL  TRIPWIRE for unresolved 0x3a76
# x06cac0+0xb18: unresolved 0x3a76 -> tripwire 0xfb920
# x06cac0+0xb60: unresolved 0x3a76 -> tripwire 0xfb920
# x06cac0+0xbac: unresolved 0x3a76 -> tripwire 0xfb920
# pcrel_escape_fix x06cac0: 0 escapes -> 0 trampolines (0 tripwired), pad 0xebc..0xf1c
code_file 0x0d3ef0 +0xca8  donovan x06cac0 code (from vsav2 0x06CAC0)
data_file 0x0d4b98 +0x274  donovan x06cac0 RAW TABLES (unencrypted; vs2 0x06D768)
code   0x0fb930 ILLEGAL  TRIPWIRE for unresolved 0x281696
# x088512+0x348: unresolved 0x281696 -> tripwire 0xfb930
code   0x0fb940 ILLEGAL  TRIPWIRE for unresolved 0x289b14
# x088512+0x126a: unresolved 0x289b14 -> tripwire 0xfb940
# x088512+0x127c: unresolved 0x289b14 -> tripwire 0xfb940
code   0x0fb950 ILLEGAL  TRIPWIRE for unresolved 0x28ed08
# x088512+0x1de2: unresolved 0x28ed08 -> tripwire 0xfb950
code   0x0fb960 ILLEGAL  TRIPWIRE for unresolved 0x36784a
# x088512+0x1dee: unresolved 0x36784a -> tripwire 0xfb960
code   0x0fb970 ILLEGAL  TRIPWIRE for unresolved 0x2695d0
# x088512+0x2894: unresolved 0x2695d0 -> tripwire 0xfb970
code   0x0fb980 ILLEGAL  TRIPWIRE for unresolved 0x2abd58
# x088512+0x359c: unresolved 0x2abd58 -> tripwire 0xfb980
# x088512+0x2be6: port_patch 000e -> 000c (companion queue class 7 (vs2-only) -> vsavj class 6 (the Anita precedent))
# x088512+0x22c: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x088512+0x1814: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x088512+0x2bee: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x088512+0x2d12: port_patch 3d7c20000018 -> 3d7c30000018 (companion-piece bank setter: effect page bank 1 -> WIDE bank 5 (native codes))
# x088512+0x3a02: port_patch 397c20000018 -> 397c30000018 (companion-piece bank setter: effect page bank 1 -> WIDE bank 5 (native codes))
# x088512+0x3a40: port_patch 397c20000018 -> 397c30000018 (companion-piece bank setter: effect page bank 1 -> WIDE bank 5 (native codes))
# x088512+0x3ae4: data_in_code reroute -> helper 0x3faec0, table 0x3fadc0 (DATA view of vsav2 0x08c042; pod-zone word offset/record table (a3 re-derived from it; self-relative))
code_file 0x0d4e10 +0x3b78  donovan x088512 code (from vsav2 0x088512)
data_file 0x0d8988 +0x20  donovan x088512 RAW TABLES (unencrypted; vs2 0x08C08A)
code_file 0x0d89b0 +0x306  donovan x093460 (from vsav2 0x093460)
data_file 0x0face0 +0x900  donovan x0d143e (from vsav2 0x0D143E)
code   0x0fb990 ILLEGAL  TRIPWIRE for unresolved 0x2c31aa
# x2b7ef4+0xb0d9: unresolved 0x2c31aa -> tripwire 0xfb990
code   0x0fb9a0 ILLEGAL  TRIPWIRE for unresolved 0x2c31e4
# x2b7ef4+0xb0fd: unresolved 0x2c31e4 -> tripwire 0xfb9a0
code   0x0fb9b0 ILLEGAL  TRIPWIRE for unresolved 0x2c3236
# x2b7ef4+0xb105: unresolved 0x2c3236 -> tripwire 0xfb9b0
code   0x0fb9c0 ILLEGAL  TRIPWIRE for unresolved 0x2c325c
# x2b7ef4+0xb10d: unresolved 0x2c325c -> tripwire 0xfb9c0
code   0x0fb9d0 ILLEGAL  TRIPWIRE for unresolved 0x2c3272
# x2b7ef4+0xb115: unresolved 0x2c3272 -> tripwire 0xfb9d0
code   0x0fb9e0 ILLEGAL  TRIPWIRE for unresolved 0x2c3280
# x2b7ef4+0xb11d: unresolved 0x2c3280 -> tripwire 0xfb9e0
code   0x0fb9f0 ILLEGAL  TRIPWIRE for unresolved 0x2c3296
# x2b7ef4+0xb125: unresolved 0x2c3296 -> tripwire 0xfb9f0
code   0x0fba00 ILLEGAL  TRIPWIRE for unresolved 0x2c32a4
# x2b7ef4+0xb12d: unresolved 0x2c32a4 -> tripwire 0xfba00
code   0x0fba10 ILLEGAL  TRIPWIRE for unresolved 0x2c32b2
# x2b7ef4+0xb135: unresolved 0x2c32b2 -> tripwire 0xfba10
# x2b7ef4: effect-c5 — 5714 bank-1 codes kept NATIVE (art -> group C bank 5); 114 coord lists matched, 617 ported (11336B fragment)
data_file 0x400010 +0xb20c  donovan x2b7ef4 (from vsav2 0x2B7EF4)
data     0x3fdb20 +0x500  sprite palette block (vsav2 0x39BC9C); poke32 0x38c1d8 (table 0x38c198 row 0x10)
data     0x0fba20 +0xdc0  effect palette block (vsav2 0x3AB69C); poke32 0x38c258 (table 0x38c218 row 0x10)
poke32 0x0bceba <- 0x000d8cc0  anim_index_a[0x10] donovan anim
poke32 0x0bcf3a <- 0x000dd81c  anim_index_a2[0x10] donovan anim
poke32 0x0bcfba <- 0x000db32a  anim_index_b[0x10] donovan anim
poke32 0x0bd03a <- 0x000db2b4  anim_index_c[0x10] donovan anim
poke32 0x0bd0ba <- 0x000e3324  anim_index_proj[0x10] donovan anim
data   0x0bd8fa +0x8  param32_a[0x10] value
data   0x0bde7a +0x30  jump_params[0x10] value
poke32 0x0bd9ba <- 0x000f7770  hitbox_base[0x10] donovan hitbox
poke32 0x0bda3a <- 0x000f7650  hitbox_comp[0x10] donovan hitbox
poke32 0x0bdaba <- 0x000fa944  proj_hitbox_base[0x10] donovan hitbox_proj
poke32 0x0bdb3a <- 0x000fa910  proj_hitbox_comp[0x10] donovan hitbox_proj
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
poke32 0x0bf45a <- 0x000fa82a  tail_data_ptr[0x10] donovan hitbox
poke32 0x0bd4ba <- 0x00024ea4  dispatch_07[0x10] engine twin of 0x23afe (alias char row 0x2d68e differs)
code   0x0fc7e0 ILLEGAL  TRIPWIRE for unresolved 0x65c22
# obj_hook@0x54470 type 59: unresolved 0x65c22 -> tripwire 0xfc7e0
code   0x0fc7f0 ILLEGAL  TRIPWIRE for unresolved 0x65e5a
# obj_hook@0x54470 type 60: unresolved 0x65e5a -> tripwire 0xfc7f0
# obj_hook@0x54470 type 61: unresolved 0x65e5a -> tripwire 0xfc7f0
code   0x0fc800 ILLEGAL  TRIPWIRE for unresolved 0x66ec4
# obj_hook@0x54470 type 62: unresolved 0x66ec4 -> tripwire 0xfc800
code   0x0fc810 ILLEGAL  TRIPWIRE for unresolved 0x6717c
# obj_hook@0x54470 type 63: unresolved 0x6717c -> tripwire 0xfc810
data   0x0fc820 +0x130  proj_hook extended type table (59 vanilla + 17 ported, 12 placed)
code   0x0fc950 obj_hook thunk (ghost-clean: returns to vanilla jsr)
code   0x054470 ENGINE HOOK: dispatch -> jmp thunk; vanilla jsr (A0) at 0x54476 untouched (vanilla types identical via table copy)
code   0x0fc970 ILLEGAL  TRIPWIRE for unresolved 0x6a70c
# obj_hook@0x5e542 type 121: unresolved 0x6a70c -> tripwire 0xfc970
# obj_hook@0x5e542 type 122: unresolved 0x6a70c -> tripwire 0xfc970
# obj_hook@0x5e542 type 123: unresolved 0x6a70c -> tripwire 0xfc970
data   0x0fc980 +0x1f0  proj_hook extended type table (114 vanilla + 10 ported, 7 placed)
code   0x0fcb70 obj_hook thunk (ghost-clean: returns to vanilla jsr)
code   0x05e542 ENGINE HOOK: dispatch -> jmp thunk; vanilla jsr (A0) at 0x5e548 untouched (vanilla types identical via table copy)
code   0x0fcb90 init shim (pool latch A5+0x7966, seeder 0x16c64; flavor (A6+0x3c2) huitzil<-0x00/held 0x01 [Start bitmask 0xff8060, bit=player]) -> handler 0x0c1e60
poke32 0x0bd13a <- 0x000fcb90  dispatch_00[0x10] donovan handler via seed shim
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
data   0x40b220 +0x1d80  data_port grab_hold_keyframes PLACED (tenant at 0x10; host block 0x92c4a untouched) <- vsav2 0x0c56aa (0 fixes)
poke32 0x0be2ba <- 0x40b220  data_port grab_hold_keyframes ptr-table 0xbe27a row 0x10
data   0x0211e4        select_wheel roster21: TABLE B in place, 28 bytes over 3 new rows + 5 inbound edges
data   0x40cfa0 +0x54  select_wheel roster21 coord list (18 vanilla + 3 new)
data   0x40d000 +0x5e  select_wheel roster21 record (count 17->20, budget 0x55 CARRIED OVER, cptr -> 0x40cfa0)
poke32 0x2689fe <- 0x40d000  select_wheel roster21 record ptr (was 0x272a68; the record's ONLY referrer — vanilla record and list are untouched)
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
code   0x0fcbe0 +0x28  select_wheel roster21: march mid-row retarget 0x16/0x19 -> 0x02 (dest computation 0x2b598 jsr-routed)
code   0x0fcc10 +0x28  select_wheel roster21: march mid-row retarget 0x16/0x19 -> 0x02 (dest computation 0x2b7d8 jsr-routed)
data   0x40d060 +0x1c  select_records portrait/p1 coord list (7 pairs, vs2 0x303238)
data   0x40d080 +0x26  select_records portrait/p1 record (vs2 0x2a5e4a, 7 entries, budget 0x5b = vs2's own)
poke32 0x26746a <- 0x40d080  select_records portrait/p1 array row 0x10 (was 0x271924, the base-half alias)
data   0x40d0b0 +0x1c  select_records portrait/p2 coord list (7 pairs, vs2 0x3035a8)
data   0x40d0d0 +0x26  select_records portrait/p2 record (vs2 0x2a625a, 7 entries, budget 0x5b = vs2's own)
poke32 0x2674ea <- 0x40d0d0  select_records portrait/p2 array row 0x10 (was 0x271d36, the base-half alias)
data   0x40d100 +0x4  select_records name_banner/p1 coord list (1 pairs, vs2 0x303730)
data   0x40d110 +0xe  select_records name_banner/p1 record (vs2 0x2a64d6, 1 entries, budget 0x8 = vs2's own)
poke32 0x2675ea <- 0x40d110  select_records name_banner/p1 array row 0x10 (was 0x272148, the base-half alias)
data   0x40d120 +0x8  select_records name_banner/p2 coord list (2 pairs, vs2 0x303d9c)
data   0x40d130 +0x12  select_records name_banner/p2 record (vs2 0x2a7506, 2 entries, budget 0x3 = vs2's own)
poke32 0x26766a <- 0x40d130  select_records name_banner/p2 array row 0x10 (was 0x273052, the base-half alias)
data   0x40d150 +0x14  select_records splash_p1/p1 coord list (5 pairs, vs2 0x304028)
data   0x40d170 +0x1e  select_records splash_p1/p1 record (vs2 0x2a7b06, 5 entries, budget 0x4c = vs2's own)
poke32 0x2672ea <- 0x40d170  select_records splash_p1/p1 array row 0x10 (was 0x273462, the base-half alias)
data   0x40d190 +0x14  select_records splash_p2/p1 coord list (5 pairs, vs2 0x3042b8)
data   0x40d1b0 +0x1e  select_records splash_p2/p1 record (vs2 0x2a7e36, 5 entries, budget 0x4c = vs2's own)
poke32 0x26736a <- 0x40d1b0  select_records splash_p2/p1 array row 0x10 (was 0x2737a8, the base-half alias)
data   0x40d1d0 +0x84  select_records win_quote/p1 coord list (33 pairs, vs2 0x304bd8)
data   0x40d260 +0x8e  select_records win_quote/p1 record (vs2 0x2a881e, 33 entries, budget 0x8a = vs2's own)
poke32 0x2673ea <- 0x40d260  select_records win_quote/p1 array row 0x10 (was 0x273aee, the base-half alias)
poke32 0x268a42 <- 0x2724a2  select_records highlight/p1 array row 0x10 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x272554)
poke32 0x268ac2 <- 0x2726ce  select_records highlight/p2 array row 0x10 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x272780)
# select_records: 0 bank-1 tile placements -> select_tiles.json (only the composed records' art; the slot-0x0F splash/win-quote families are NOT placed, so that Jedah art stays vanilla)
# select_records: 236 native bank-1 tiles -> select_bank5.json (copied vs2 -> group C bank 5 by build_gfx; the drawer's bank is thunk-gated per hover)
data   0x40d2f0 +0x4b00  win_pal_variant hui_win_pal: sparse block, 8 sets of 0xa0 at stride 0xaa0 (vs2 0x3c329c stride 0xb40)
code   0x0fcc40 +0x16  win_pal_variant thunk, 1-way: hui_win_pal d6==0x10 -> a0=0x40c8f0; else vanilla pool 0x3ad700
code   0x05f1b6 +6     win_pal_variant: movea.l #pool -> jsr 0xfcc40
code   0x0fcc60 +0x1a  site_thunk tenant_jump_seq; site 0x022a0e jmp-routed
code   0x0fcc80 +0xe  site_thunk shadow_seq_guard; site 0x08245c jmp-routed
code   0x0fcc90 +0x1e  site_thunk name_bank_variant_id; site 0x05fce0 jsr-routed
code   0x0fccb0 +0x1e  site_thunk splash_bank_variant_id; site 0x06c0e0 jsr-routed
code   0x0fccd0 +0x16  site_thunk winquote_bank_variant_id; site 0x05f328 jsr-routed
data   0x411df0 +0x140  site_thunk select_pal_variant_id data block <- vsav2 0x3c12dc
code   0x0fccf0 +0x38  site_thunk select_pal_variant_id; site 0x05f146 jsr-routed
data   0x411f30 +0x54  site_thunk throw_arc_tables data block <- vsav2 0x0279b4
data   0x411f90 +0x370  site_thunk throw_arc_tables data block <- vsav2 0x027a08
code   0x0fcd30 +0x42  site_thunk throw_arc_tables; site 0x028386 jmp-routed
code   0x0fcd80 +0xe  site_thunk idmask_victim_spawn; site 0x060ef0 jmp-routed
code   0x0fcd90 +0x10  site_thunk idmask_piece_subtype; site 0x05e7d6 jmp-routed
data   0x412300 +0x100  site_thunk df_gold_variant_id data block <- vsav2 0x3abedc
code   0x0fcda0 +0x54  site_thunk df_gold_variant_id; site 0x02a8d6 jmp-routed
code   0x0fce00 +0x102  site_thunk beam_list_type6; site 0x01b6aa jmp-routed
code   0x0fcf10 +0x1d6  site_thunk index_window_018468; site 0x018460 jmp-routed
code   0x0fd0f0 +0x5e  site_thunk hitclass_map_extend; site 0x01a888 jmp-routed
code   0x0282f4 +0x2  code_word obj_bank_word_slot (slot entry -> 1000)
code   0x05f240 +0x2  code_word win_pos_x_slot (slot entry -> 00c0)
code   0x05f242 +0x2  code_word win_pos_y_slot (slot entry -> 0080)
code   0x02a8c4 +0x2  code_word df_seq_entry_10 (slot entry -> 0032)
code   0x080aec +0x4  code_ptr beam_effect_class16 (00080b44 -> 000d89b0 = x093460+0x0)
# image: extend to 0x600000 (4 x 0x80000 member(s): vsw.41, vsw.42, vsw.43, vsw.44)
