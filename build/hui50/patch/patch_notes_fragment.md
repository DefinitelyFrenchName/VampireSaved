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
data_file 0x0d8dc0 +0x1e800  donovan anim (from vsav2 0x245872)
data_file 0x0f75c0 +0x190  donovan aux0_0 (from vsav2 0x334170)
data_file 0x3ec720 +0xe620  donovan aux0_1 (from vsav2 0x336560)
# code+0x9c: pcrel16 -> x057456@0x574b0 (disp 0x2784 -> 0x2784 after placement)
# code+0x102: pcrel16 -> x057456@0x574b0 (disp 0x271e -> 0x271e after placement)
# code+0x15a: pcrel16 -> x057456@0x574b6 (disp 0x26cc -> 0x26cc after placement)
# code+0x1a4: pcrel16 -> x057456@0x574b6 (disp 0x2682 -> 0x2682 after placement)
# code+0x2f4: pcrel16 -> x057456@0x574b0 (disp 0x252c -> 0x252c after placement)
code   0x0fc540 farm-port stub for 0x2916c (param at 0x0fc520, common 0x29f4a)
code   0x0fc560 farm-port stub for 0x29184 (param at 0x0fc550, common 0x29f4a)
code   0x0fc580 farm-port stub for 0x2918c (param at 0x0fc570, common 0x29f4a)
code   0x0fc590 slot-clearing alloc wrapper for 0x15702 -> 0x16fba (0x80 cleared, +8 preserved)
# code+0x9ac: pcrel16 -> x057456@0x574b0 (disp 0x1e74 -> 0x1e74 after placement)
# code+0xd3a: pcrel16 -> x057456@0x574b0 (disp 0x1ae6 -> 0x1ae6 after placement)
# code+0xfe2: pcrel16 -> x057456@0x574b0 (disp 0x183e -> 0x183e after placement)
# code+0x10da: pcrel16 -> x057456@0x574b0 (disp 0x1746 -> 0x1746 after placement)
code   0x0fc5c0 sound stub for 0x4ddc (vsavj sfx id 0x84)
code   0x0fc5e0 sound stub for 0x4f48 (vsavj sfx id 0x8b)
# code+0x141a: pcrel16 -> x057456@0x574b0 (disp 0x1406 -> 0x1406 after placement)
# code+0x142a: pcrel16 -> x057456@0x574b0 (disp 0x13f6 -> 0x13f6 after placement)
# code+0x151a: pcrel16 -> x057456@0x574b0 (disp 0x1306 -> 0x1306 after placement)
# code+0x18d0: pcrel16 -> x057456@0x574b0 (disp 0xf50 -> 0xf50 after placement)
# code+0x18e0: pcrel16 -> x057456@0x574b0 (disp 0xf40 -> 0xf40 after placement)
code   0x0fc600 sound stub for 0x4e92 (vsavj sfx id 0x93)
# code+0x197c: pcrel16 -> x057456@0x574b0 (disp 0xea4 -> 0xea4 after placement)
# code+0x1a38: pcrel16 -> x057456@0x574c2 (disp 0xdfa -> 0xdfa after placement)
# code+0x1a46: pcrel16 -> x057456@0x574c2 (disp 0xdec -> 0xdec after placement)
# code+0x1a86: pcrel16 -> x057456@0x574c2 (disp 0xdac -> 0xdac after placement)
# code+0x1b94: pcrel16 -> x057456@0x574b0 (disp 0xc8c -> 0xc8c after placement)
# code+0x1c94: pcrel16 -> x057456@0x574b0 (disp 0xb8c -> 0xb8c after placement)
# code+0x1f06: pcrel16 -> x057456@0x574bc (disp 0x926 -> 0x926 after placement)
code   0x0fc620 sound stub for 0x4ec6 (vsavj sfx id 0x95)
code   0x0fc640 sound stub for 0x4e10 (vsavj sfx id 0x85)
# code+0x20de: pcrel16 -> x057456@0x574b0 (disp 0x742 -> 0x742 after placement)
# code+0x2192: pcrel16 -> x057456@0x574b0 (disp 0x68e -> 0x68e after placement)
# code+0x21aa: pcrel16 -> x057456@0x574b0 (disp 0x676 -> 0x676 after placement)
# code+0x2226: pcrel16 -> x057456@0x574b0 (disp 0x5fa -> 0x5fa after placement)
# code+0x2392: pcrel16 -> code@0x57024 (disp 0x2 -> 0x2 after placement)
# code+0x249c: pcrel16 -> x057456@0x574b0 (disp 0x384 -> 0x384 after placement)
code   0x0fc660 sound stub for 0x4e5e (vsavj sfx id 0x91)
code   0x0fc680 sound stub for 0x4e78 (vsavj sfx id 0x92)
# code+0x253c: pcrel16 -> x057456@0x574b0 (disp 0x2e4 -> 0x2e4 after placement)
# code+0x2546: pcrel16 -> code@0x571d8 (disp 0x2 -> 0x2 after placement)
# code+0x13bc: data_in_code reroute -> helper 0x3fad50, table 0x3fad40 (DATA view of vsav2 0x056074; FG capture-pose random table (native draws seqs 1/3/5))
# code+0x1390: data_in_code reroute -> helper 0x3fad70, table 0x3fad60 (DATA view of vsav2 0x056064; FG capture-pose table 2 (seqs 0x56-0x59))
# code+0x17c8: data_in_code reroute -> helper 0x3fad90, table 0x3fad80 (DATA view of vsav2 0x05649c; capture-pose table 3 (seqs 0x56-0x59 twin))
# code+0x17f4: data_in_code reroute -> helper 0x3fadb0, table 0x3fada0 (DATA view of vsav2 0x0564ac; capture-pose table 4 (01/03/05 twin))
code_file 0x0bf6a0 +0x27c6  donovan code (from vsav2 0x054C90)
data_file 0x0f7750 +0x32b2  donovan hitbox (from vsav2 0x0C4250)
# hitbox_proj+0x17d: region_fix 52 -> 06 (trap dome hit record 1: class 0x52 -> 0x06 (vs2-alias-proven; routes vsavj electric-shake 0x23AC8))
# hitbox_proj+0x19d: region_fix 52 -> 06 (trap dome hit record 2: class 0x52 -> 0x06 (vs2-alias-proven))
data_file 0x0faa10 +0x3c6  donovan hitbox_proj (from vsav2 0x0D05C0)
code   0x0fc6a0 ILLEGAL  TRIPWIRE for unresolved 0x2cd38
# x022400+0x112: unresolved 0x2cd38 -> tripwire 0xfc6a0
# bank_ref 0xd8998 -> 0xbe7fa (delta rule, 16B byte-identical)
code   0x0fc6b0 ILLEGAL  TRIPWIRE for unresolved 0x7f5f4
# x022400+0xa82: unresolved 0x7f5f4 -> tripwire 0xfc6b0
code   0x0fc6c0 ILLEGAL  TRIPWIRE for unresolved 0x82480
# x022400+0xada: unresolved 0x82480 -> tripwire 0xfc6c0
# bank_ref 0xd9638 -> 0xbf49a (delta rule, known table base)
code   0x0fc6d0 ILLEGAL  TRIPWIRE for unresolved 0x828fe
# x022400+0xb66: unresolved 0x828fe -> tripwire 0xfc6d0
# bank_ref 0xd8998 -> 0xbe7fa (delta rule, 16B byte-identical)
code   0x0fc6e0 ILLEGAL  TRIPWIRE for unresolved 0xbdb0
# x022400+0x12ac: unresolved 0xbdb0 -> tripwire 0xfc6e0
# x022400+0x12fa: unresolved 0x2cd38 -> tripwire 0xfc6a0
code   0x0fc6f0 ILLEGAL  TRIPWIRE for unresolved 0x8278c
# x022400+0x14c0: unresolved 0x8278c -> tripwire 0xfc6f0
code   0x0fc700 ILLEGAL  TRIPWIRE for unresolved 0x7b368
# x022400+0x15c8: unresolved 0x7b368 -> tripwire 0xfc700
code   0x0fc710 ILLEGAL  TRIPWIRE for unresolved 0x3d1c
# x022400+0x662: unresolved 0x3d1c -> tripwire 0xfc710
code   0x0fc720 ILLEGAL  TRIPWIRE for unresolved 0x3dc6
# x022400+0x696: unresolved 0x3dc6 -> tripwire 0xfc720
code   0x0fc730 ILLEGAL  TRIPWIRE for unresolved 0x3e70
# x022400+0x80c: unresolved 0x3e70 -> tripwire 0xfc730
# x022400+0x86c: unresolved 0x3d1c -> tripwire 0xfc710
code   0x0fc740 ILLEGAL  TRIPWIRE for unresolved 0x3c44
# x022400+0x1078: unresolved 0x3c44 -> tripwire 0xfc740
code   0x0fc750 ILLEGAL  TRIPWIRE for unresolved 0x3cb0
# x022400+0x13a0: unresolved 0x3cb0 -> tripwire 0xfc750
code   0x0fc760 ILLEGAL  TRIPWIRE for unresolved 0x3a28
# x022400+0x13e0: unresolved 0x3a28 -> tripwire 0xfc760
# x022400+0x13ee: unresolved 0x3a28 -> tripwire 0xfc760
code   0x0fc770 ILLEGAL  TRIPWIRE for unresolved 0x3980
# x022400+0x1404: unresolved 0x3980 -> tripwire 0xfc770
code   0x0fc780 ILLEGAL  TRIPWIRE for unresolved 0x41be
# x022400+0x14ce: unresolved 0x41be -> tripwire 0xfc780
# x022400+0x82: char-id imm 0x10 -> 0x10
# x022400+0x1618: ESCAPE TRIPWIRE for unresolved pcrel target 0x24d12
# x022400+0x1624: ESCAPE TRIPWIRE for unresolved pcrel target 0x275e4
# pcrel_escape_fix x022400: 118 escapes -> 11 trampolines (2 tripwired), pad 0x1600..0x1780
code_file 0x0c7070 +0x1780  donovan x022400 (from vsav2 0x022400)
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
# x028122+0x9a0: port_patch 3b7c0001b498 -> 3b7c0001b446 (obj-hit dmg: flag var -> vsavj layout (-0x4BBA))
# x028122+0x9a6: port_patch 426db494 -> 426db442 (obj-hit dmg: clr damage var -> vsavj layout (-0x4BBE))
# x028122+0x9b6: port_patch 3b42b494 -> 3b42b442 (obj-hit dmg: scaled damage -> vsavj layout (-0x4BBE))
# x028122+0x9ba: port_patch 3b7c0000b498 -> 3b7c0000b446 (obj-hit dmg: flag clear -> vsavj layout (-0x4BBA))
# x028122+0x9c0: port_patch 426db496 -> 426db444 (obj-hit dmg: clr white var -> vsavj layout (-0x4BBC))
# x028122+0x9d0: port_patch 3b42b496 -> 3b42b444 (obj-hit dmg: white damage -> vsavj layout (-0x4BBC))
code_file 0x0ca210 +0xe00  donovan x028122 (from vsav2 0x028122)
code   0x0fc790 slot-clearing alloc wrapper for 0x1572e -> 0x16fe6 (0x80 cleared, +8 preserved)
code   0x0fc7d0 farm-port stub for 0x2915c (param at 0x0fc7c0, common 0x29f4a)
code   0x0fc7f0 farm-port stub for 0x29164 (param at 0x0fc7e0, common 0x29f4a)
code   0x0fc800 sound stub for 0x4f96 (vsavj sfx id 0xa1)
code   0x0fc820 ILLEGAL  TRIPWIRE for unresolved 0x4223c
# x057456+0x3b42: unresolved 0x4223c -> tripwire 0xfc820
code   0x0fc830 ILLEGAL  TRIPWIRE for unresolved 0x42cee
# x057456+0x421a: unresolved 0x42cee -> tripwire 0xfc830
code   0x0fc840 ILLEGAL  TRIPWIRE for unresolved 0x448d4
# x057456+0x50cc: unresolved 0x448d4 -> tripwire 0xfc840
# x057456+0x418e: char-id imm 0x10 -> 0x10
# x057456+0x1f36: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H own zone): vs2 bank 3 -> WIDE bank 4)
code_file 0x0c1e66 +0x5200  donovan x057456 (from vsav2 0x057456)
code   0x0fc850 ILLEGAL  TRIPWIRE for unresolved 0x12f484
# x05c800+0x152a: unresolved 0x12f484 -> tripwire 0xfc850
# x05c800+0x16a4: unresolved 0x12f484 -> tripwire 0xfc850
code   0x0fc860 ILLEGAL  TRIPWIRE for unresolved 0x167bf4
# x05c800+0x2622: unresolved 0x167bf4 -> tripwire 0xfc860
# x05c800+0x2a20: unresolved 0x167bf4 -> tripwire 0xfc860
code   0x0fc870 ILLEGAL  TRIPWIRE for unresolved 0x17f176
# x05c800+0x2ae4: unresolved 0x17f176 -> tripwire 0xfc870
# x05c800+0x3034: unresolved 0x17f176 -> tripwire 0xfc870
code   0x0fc880 ILLEGAL  TRIPWIRE for unresolved 0x181592
# x05c800+0x3072: unresolved 0x181592 -> tripwire 0xfc880
# x05c800+0x1456: char-id imm 0x10 -> 0x10
# x05c800+0x738: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x05c800+0x58d4: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x05c800+0x5994: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# pcrel_escape_fix x05c800: 2 escapes -> 1 trampolines (0 tripwired), pad 0x6a00..0x6a20
code_file 0x0cb010 +0x6a20  donovan x05c800 (from vsav2 0x05C800)
code_file 0x0d1a30 +0x280  donovan x0672d0 (from vsav2 0x0672D0)
code_file 0x0d1cb0 +0x2f6  donovan x067550 (from vsav2 0x067550)
code   0x0fc890 sound stub for 0x4fb0 (vsavj sfx id 0xa0)
code   0x0fc8b0 sound stub for 0x4fca (vsavj sfx id 0xa5)
code_file 0x0d1fb0 +0x1ba  donovan x067846 (from vsav2 0x067846)
code_file 0x0d2170 +0x60c  donovan x067a00 (from vsav2 0x067A00)
# x06800c+0x354: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x396: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x3de: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x422: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
code_file 0x0d2780 +0x44c  donovan x06800c (from vsav2 0x06800C)
code   0x0fc8d0 sound stub for 0x4f2e (vsavj sfx id 0x199)
code_file 0x0d2bd0 +0x310  donovan x068458 (from vsav2 0x068458)
code_file 0x0d2ee0 +0x264  donovan x068768 (from vsav2 0x068768)
code   0x0fc8f0 sound stub for 0x4efa (vsavj sfx id 0x90)
code_file 0x0d3150 +0x2ac  donovan x0689cc (from vsav2 0x0689CC)
code   0x0fc910 +0x40  patched clone of 0x5459a for vs2 0x5c77e (unmasked set-anim entry; false byte-matc)
code   0x0fc950 sound stub for 0x4f62 (vsavj sfx id 0x7f)
code_file 0x0d3400 +0x3ce  donovan x068c78 (from vsav2 0x068C78)
code_file 0x0d37d0 +0x2b0  donovan x069046 (from vsav2 0x069046)
# x0692f6+0x19a: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
code_file 0x0d3a80 +0x368  donovan x0692f6 (from vsav2 0x0692F6)
code_file 0x0d3df0 +0x100  donovan x06965e (from vsav2 0x06965E)
code   0x0fc970 ILLEGAL  TRIPWIRE for unresolved 0x22f2d2
# x06cac0+0x546: unresolved 0x22f2d2 -> tripwire 0xfc970
code   0x0fc980 ILLEGAL  TRIPWIRE for unresolved 0x4cb0
# x06cac0+0x552: unresolved 0x4cb0 -> tripwire 0xfc980
code   0x0fc990 ILLEGAL  TRIPWIRE for unresolved 0x4c96
# x06cac0+0x586: unresolved 0x4c96 -> tripwire 0xfc990
# x06cac0+0x58e: unresolved 0x22f2d2 -> tripwire 0xfc970
# bank_ref 0xd7118 -> 0xbcf7a (delta rule, known table base)
# bank_ref 0xd7118 -> 0xbcf7a (delta rule, known table base)
code   0x0fc9a0 ILLEGAL  TRIPWIRE for unresolved 0x3a90
# x06cac0+0xacc: unresolved 0x3a90 -> tripwire 0xfc9a0
code   0x0fc9b0 ILLEGAL  TRIPWIRE for unresolved 0x3a76
# x06cac0+0xb18: unresolved 0x3a76 -> tripwire 0xfc9b0
# x06cac0+0xb60: unresolved 0x3a76 -> tripwire 0xfc9b0
# x06cac0+0xbac: unresolved 0x3a76 -> tripwire 0xfc9b0
# pcrel_escape_fix x06cac0: 0 escapes -> 0 trampolines (0 tripwired), pad 0xebc..0xf1c
code_file 0x0d3ef0 +0xca8  donovan x06cac0 code (from vsav2 0x06CAC0)
data_file 0x0d4b98 +0x274  donovan x06cac0 RAW TABLES (unencrypted; vs2 0x06D768)
code   0x0fc9c0 ILLEGAL  TRIPWIRE for unresolved 0x281696
# x088512+0x348: unresolved 0x281696 -> tripwire 0xfc9c0
code   0x0fc9d0 ILLEGAL  TRIPWIRE for unresolved 0x289b14
# x088512+0x126a: unresolved 0x289b14 -> tripwire 0xfc9d0
# x088512+0x127c: unresolved 0x289b14 -> tripwire 0xfc9d0
code   0x0fc9e0 ILLEGAL  TRIPWIRE for unresolved 0x28ed08
# x088512+0x1de2: unresolved 0x28ed08 -> tripwire 0xfc9e0
code   0x0fc9f0 ILLEGAL  TRIPWIRE for unresolved 0x36784a
# x088512+0x1dee: unresolved 0x36784a -> tripwire 0xfc9f0
code   0x0fca00 sound stub for 0x50ee (vsavj sfx id 0x7e)
code   0x0fca20 sound stub for 0x50a0 (vsavj sfx id 0x7b)
code   0x0fca40 sound stub for 0x50d4 (vsavj sfx id 0x7d)
code   0x0fca60 sound stub for 0x50ba (vsavj sfx id 0x7c)
code   0x0fca80 sound stub for 0x4e2a (vsavj sfx id 0x8f)
code   0x0fcaa0 sound stub for 0x4df6 (vsavj sfx id 0x86)
code   0x0fcac0 ILLEGAL  TRIPWIRE for unresolved 0x2695d0
# x088512+0x2894: unresolved 0x2695d0 -> tripwire 0xfcac0
code   0x0fcad0 ILLEGAL  TRIPWIRE for unresolved 0x2abd58
# x088512+0x359c: unresolved 0x2abd58 -> tripwire 0xfcad0
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
code_file 0x0d89b0 +0x100  donovan x0926e4 (from vsav2 0x0926E4)
code_file 0x0d8ab0 +0x306  donovan x093460 (from vsav2 0x093460)
data_file 0x0fade0 +0x900  donovan x0d143e (from vsav2 0x0D143E)
data_file 0x0fb6e0 +0xe3c  donovan x100000 (from vsav2 0x100000)
code   0x0fcae0 ILLEGAL  TRIPWIRE for unresolved 0x2c31aa
# x2b7ef4+0xb0d9: unresolved 0x2c31aa -> tripwire 0xfcae0
code   0x0fcaf0 ILLEGAL  TRIPWIRE for unresolved 0x2c31e4
# x2b7ef4+0xb0fd: unresolved 0x2c31e4 -> tripwire 0xfcaf0
code   0x0fcb00 ILLEGAL  TRIPWIRE for unresolved 0x2c3236
# x2b7ef4+0xb105: unresolved 0x2c3236 -> tripwire 0xfcb00
code   0x0fcb10 ILLEGAL  TRIPWIRE for unresolved 0x2c325c
# x2b7ef4+0xb10d: unresolved 0x2c325c -> tripwire 0xfcb10
code   0x0fcb20 ILLEGAL  TRIPWIRE for unresolved 0x2c3272
# x2b7ef4+0xb115: unresolved 0x2c3272 -> tripwire 0xfcb20
code   0x0fcb30 ILLEGAL  TRIPWIRE for unresolved 0x2c3280
# x2b7ef4+0xb11d: unresolved 0x2c3280 -> tripwire 0xfcb30
code   0x0fcb40 ILLEGAL  TRIPWIRE for unresolved 0x2c3296
# x2b7ef4+0xb125: unresolved 0x2c3296 -> tripwire 0xfcb40
code   0x0fcb50 ILLEGAL  TRIPWIRE for unresolved 0x2c32a4
# x2b7ef4+0xb12d: unresolved 0x2c32a4 -> tripwire 0xfcb50
code   0x0fcb60 ILLEGAL  TRIPWIRE for unresolved 0x2c32b2
# x2b7ef4+0xb135: unresolved 0x2c32b2 -> tripwire 0xfcb60
# x2b7ef4: effect-c5 — 5714 bank-1 codes kept NATIVE (art -> group C bank 5); 114 coord lists matched, 617 ported (11336B fragment)
data_file 0x400010 +0xb20c  donovan x2b7ef4 (from vsav2 0x2B7EF4)
data     0x3fdb20 +0x500  sprite palette block (vsav2 0x39BC9C); poke32 0x38c1d8 (table 0x38c198 row 0x10)
data     0x0fcb70 +0xdc0  effect palette block (vsav2 0x3AB69C); poke32 0x38c258 (table 0x38c218 row 0x10)
poke32 0x0bceba <- 0x000d8dc0  anim_index_a[0x10] donovan anim
poke32 0x0bcf3a <- 0x000dd91c  anim_index_a2[0x10] donovan anim
poke32 0x0bcfba <- 0x000db42a  anim_index_b[0x10] donovan anim
poke32 0x0bd03a <- 0x000db3b4  anim_index_c[0x10] donovan anim
poke32 0x0bd0ba <- 0x000e3424  anim_index_proj[0x10] donovan anim
data   0x0bd8fa +0x8  param32_a[0x10] value
data   0x0bde7a +0x30  jump_params[0x10] value
poke32 0x0bd9ba <- 0x000f7870  hitbox_base[0x10] donovan hitbox
poke32 0x0bda3a <- 0x000f7750  hitbox_comp[0x10] donovan hitbox
poke32 0x0bdaba <- 0x000faa44  proj_hitbox_base[0x10] donovan hitbox_proj
poke32 0x0bdb3a <- 0x000faa10  proj_hitbox_comp[0x10] donovan hitbox_proj
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
# tail_data_ptr: ptr row owned by sound_table hui_sfx_records — generic repoint suppressed (14z-65)
poke32 0x0bf05a <- 0x000fb6e0  ai_script_0[0x10] donovan x100000
poke32 0x0bf0da <- 0x000fb7c0  ai_script_1[0x10] donovan x100000
poke32 0x0bf15a <- 0x000fbfec  ai_script_2[0x10] donovan x100000
poke32 0x0bf1da <- 0x000fc506  ai_script_3[0x10] donovan x100000
poke32 0x0bd4ba <- 0x00024ea4  dispatch_07[0x10] engine twin of 0x23afe (alias char row 0x2d68e differs)
code   0x0fd930 ILLEGAL  TRIPWIRE for unresolved 0x65c22
# obj_hook@0x54470 type 59: unresolved 0x65c22 -> tripwire 0xfd930
code   0x0fd940 ILLEGAL  TRIPWIRE for unresolved 0x65e5a
# obj_hook@0x54470 type 60: unresolved 0x65e5a -> tripwire 0xfd940
# obj_hook@0x54470 type 61: unresolved 0x65e5a -> tripwire 0xfd940
code   0x0fd950 ILLEGAL  TRIPWIRE for unresolved 0x66ec4
# obj_hook@0x54470 type 62: unresolved 0x66ec4 -> tripwire 0xfd950
code   0x0fd960 ILLEGAL  TRIPWIRE for unresolved 0x6717c
# obj_hook@0x54470 type 63: unresolved 0x6717c -> tripwire 0xfd960
code   0x0fd970 +0x15c  obj_walker: 0x54458 relocated verbatim + its extended type table at +0x2c (59 vanilla + 17 ported, 12 placed); dispatch site 0x54470 left VANILLA
code   2 caller operand(s) of jsr 0x54458 -> 0x0fd970 (0x009436, 0x020310)
code   0x0fdad0 ILLEGAL  TRIPWIRE for unresolved 0x6a70c
# obj_hook@0x5e542 type 121: unresolved 0x6a70c -> tripwire 0xfdad0
# obj_hook@0x5e542 type 122: unresolved 0x6a70c -> tripwire 0xfdad0
# obj_hook@0x5e542 type 123: unresolved 0x6a70c -> tripwire 0xfdad0
code   0x0fdae0 +0x21c  obj_walker: 0x5e52a relocated verbatim + its extended type table at +0x2c (114 vanilla + 10 ported, 7 placed); dispatch site 0x5e542 left VANILLA
code   21 caller operand(s) of jsr 0x5e52a -> 0x0fdae0 (0x0053f6, 0x005410, 0x00577c, 0x0057a8, 0x00590a, 0x005ebc, 0x00943c, 0x009caa, 0x009f36, 0x00a188, 0x00a804, 0x00abcc, 0x010dfa, 0x012a3e, 0x012d16, 0x012e4c, 0x012e66, 0x020316, 0x021638, 0x021ada, 0x021dea)
code   0x0fdd00 init shim (pool latch A5+0x7966, seeder 0x16c64; flavor (A6+0x3c2) huitzil<-0x00/held 0x01 [Start bitmask 0xff8060, bit=player]) -> handler 0x0c1e60
poke32 0x0bd13a <- 0x000fdd00  dispatch_00[0x10] donovan handler via seed shim
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
poke16 0x5fff00 <- 0x82e  aux voice_alias_thunk_w00
poke16 0x5fff02 <- 0x0  aux voice_alias_thunk_w01
poke16 0x5fff04 <- 0x70  aux voice_alias_thunk_w02
poke16 0x5fff06 <- 0x6710  aux voice_alias_thunk_w03
poke16 0x5fff08 <- 0xc41  aux voice_alias_thunk_w04
poke16 0x5fff0a <- 0x58  aux voice_alias_thunk_w05
poke16 0x5fff0c <- 0x6506  aux voice_alias_thunk_w06
poke16 0x5fff0e <- 0xc41  aux voice_alias_thunk_w07
poke16 0x5fff10 <- 0xa7  aux voice_alias_thunk_w08
poke16 0x5fff12 <- 0x6504  aux voice_alias_thunk_w09
poke16 0x5fff14 <- 0x641  aux voice_alias_thunk_w10
poke16 0x5fff16 <- 0x300  aux voice_alias_thunk_w11
poke16 0x5fff18 <- 0x4ef9  aux voice_alias_thunk_w12
poke16 0x5fff1a <- 0x0  aux voice_alias_thunk_w13
poke16 0x5fff1c <- 0x3316  aux voice_alias_thunk_w14
data   0x40b220 +0x1d80  data_port grab_hold_keyframes PLACED (tenant at 0x10; host block 0x92c4a untouched) <- vsav2 0x0c56aa (0 fixes)
poke32 0x0be2ba <- 0x40b220  data_port grab_hold_keyframes ptr-table 0xbe27a row 0x10
data   0x00b668 +0x40  data_port voice_borrow_candidates_a <- vsav2 0x009f2a (0 fixes)
data   0x00bf68 +0x40  data_port voice_borrow_voicenums_b <- vsav2 0x00a82a (4 fixes)
data   0x40cfa0 +0xee0  data_port capture_kf_bulleta PLACED (slot_rows; vanilla block 0x92c4a untouched) <- vsav2 0x0a1dbe (0 fixes)
poke32 0x0be27a <- 0x40cfa0  data_port capture_kf_bulleta ptr-table 0xbe27a row 0x00 (slot_rows)
data   0x40de80 +0x1240  data_port capture_kf_demitri PLACED (slot_rows; vanilla block 0x94954 untouched) <- vsav2 0x0a3d88 (0 fixes)
poke32 0x0be27e <- 0x40de80  data_port capture_kf_demitri ptr-table 0xbe27a row 0x01 (slot_rows)
data   0x40f0c0 +0xdc0  data_port capture_kf_gallon PLACED (slot_rows; vanilla block 0x968de untouched) <- vsav2 0x0a61d2 (0 fixes)
poke32 0x0be282 <- 0x40f0c0  data_port capture_kf_gallon ptr-table 0xbe27a row 0x02 (slot_rows)
data   0x40fe80 +0x1f30  data_port capture_kf_victor PLACED (slot_rows; vanilla block 0x98c28 untouched) <- vsav2 0x0a8824 (0 fixes)
poke32 0x0be286 <- 0x40fe80  data_port capture_kf_victor ptr-table 0xbe27a row 0x03 (slot_rows)
data   0x411db0 +0x1df0  data_port capture_kf_zabel PLACED (slot_rows; vanilla block 0x9baea untouched) <- vsav2 0x0abc56 (0 fixes)
poke32 0x0be28a <- 0x411db0  data_port capture_kf_zabel ptr-table 0xbe27a row 0x04 (slot_rows)
poke32 0x0be2a6 <- 0x411db0  data_port capture_kf_zabel ptr-table 0xbe27a row 0x0b (slot_rows)
data   0x413ba0 +0x12a8  data_port capture_kf_morrigan PLACED (slot_rows; vanilla block 0xa0010 untouched) <- vsav2 0x0aedb4 (0 fixes)
poke32 0x0be28e <- 0x413ba0  data_port capture_kf_morrigan ptr-table 0xbe27a row 0x05 (slot_rows)
data   0x414e50 +0x3a0  data_port capture_kf_anakaris PLACED (slot_rows; vanilla block 0xa204e untouched) <- vsav2 0x0b119a (0 fixes)
poke32 0x0be292 <- 0x414e50  data_port capture_kf_anakaris ptr-table 0xbe27a row 0x06 (slot_rows)
data   0x4151f0 +0x30a0  data_port capture_kf_felicia PLACED (slot_rows; vanilla block 0xa3990 untouched) <- vsav2 0x0b2bac (0 fixes)
poke32 0x0be296 <- 0x4151f0  data_port capture_kf_felicia ptr-table 0xbe27a row 0x07 (slot_rows)
data   0x418290 +0x940  data_port capture_kf_bishamon PLACED (slot_rows; vanilla block 0xa74aa untouched) <- vsav2 0x0b6f22 (0 fixes)
poke32 0x0be29a <- 0x418290  data_port capture_kf_bishamon ptr-table 0xbe27a row 0x08 (slot_rows)
poke32 0x0be2da <- 0x418290  data_port capture_kf_bishamon ptr-table 0xbe27a row 0x18 (slot_rows)
data   0x418bd0 +0xa60  data_port capture_kf_aulbath PLACED (slot_rows; vanilla block 0xa8aec untouched) <- vsav2 0x0b8724 (0 fixes)
poke32 0x0be29e <- 0x418bd0  data_port capture_kf_aulbath ptr-table 0xbe27a row 0x09 (slot_rows)
data   0x419630 +0x1510  data_port capture_kf_sasquatch PLACED (slot_rows; vanilla block 0xaa2e2 untouched) <- vsav2 0x0ba152 (0 fixes)
poke32 0x0be2a2 <- 0x419630  data_port capture_kf_sasquatch ptr-table 0xbe27a row 0x0a (slot_rows)
data   0x41ab40 +0xb80  data_port capture_kf_qbee PLACED (slot_rows; vanilla block 0xac9ce untouched) <- vsav2 0x0bcbb6 (0 fixes)
poke32 0x0be2aa <- 0x41ab40  data_port capture_kf_qbee ptr-table 0xbe27a row 0x0c (slot_rows)
data   0x41b6c0 +0x618  data_port capture_kf_leilei PLACED (slot_rows; vanilla block 0xae324 untouched) <- vsav2 0x0be728 (0 fixes)
poke32 0x0be2ae <- 0x41b6c0  data_port capture_kf_leilei ptr-table 0xbe27a row 0x0d (slot_rows)
data   0x41bce0 +0x11b0  data_port capture_kf_lilith PLACED (slot_rows; vanilla block 0xafbfe untouched) <- vsav2 0x0c010e (0 fixes)
poke32 0x0be2b2 <- 0x41bce0  data_port capture_kf_lilith ptr-table 0xbe27a row 0x0e (slot_rows)
data   0x41ce90 +0x1cf0  data_port capture_kf_jedah PLACED (slot_rows; vanilla block 0xb19f8 untouched) <- vsav2 0x0c2430 (0 fixes)
poke32 0x0be2b6 <- 0x41ce90  data_port capture_kf_jedah ptr-table 0xbe27a row 0x0f (slot_rows)
data   0x41eb80 +0xc0  sound_table hui_sfx_records <- vsav2 0x0c742a (24 entries; kept ['0x110@1', '0x111@2', '0x112@3', '0x08d@5', '0x07f@6', '0x080@7', '0x081@8', '0x082@9', '0x0d8@10', '0x199@11', '0x083@12', '0x088@13', '0x089@14', '0x08a@15', '0x08b@16', '0x08c@17', '0x08e@18', '0x096@19', '0x094@20', '0x199@21', '0x198@22']; zeroed 2 unplayable ids; remapped [(5, '0x745', '0x8d'), (6, '0x735', '0x7f'), (7, '0x736', '0x80'), (8, '0x737', '0x81'), (9, '0x738', '0x82'), (10, '0x739', '0xd8'), (11, '0x73a', '0x199'), (12, '0x73b', '0x83'), (13, '0x740', '0x88'), (14, '0x741', '0x89'), (15, '0x742', '0x8a'), (16, '0x743', '0x8b'), (17, '0x744', '0x8c'), (18, '0x746', '0x8e'), (19, '0x74e', '0x96'), (20, '0x74c', '0x94')])
poke32 0x0bf45a <- 0x41eb80  sound_table hui_sfx_records per-char ptr row 0x10 (was 0x938ba)
data   0x0211e4        select_wheel roster21: TABLE B in place, 28 bytes over 3 new rows + 5 inbound edges
# select_wheel roster21: version_text 'M10' -> 3 glyph entries at screen (324,202), pal row 0x19, codes 0x1fe40+ (authored tiles via wheel_bank5.json)
data   0x41ec40 +0x6c  select_wheel roster21 coord list (18 vanilla + 3 new + 3 cell outlines + 3 version glyphs)
data   0x41ecb0 +0x76  select_wheel roster21 record (count 17->26, budget 0x55 CARRIED OVER, cptr -> 0x41ec40)
poke32 0x2689fe <- 0x41ecb0  select_wheel roster21 record ptr (was 0x272a68; the record's ONLY referrer — vanilla record and list are untouched)
code   0x05fb22 +4     select_wheel roster21: highlight base row 0x10 <- (165,77) (was the row 0x00 alias)
code   0x05fb26 +4     select_wheel roster21: highlight base row 0x11 <- (191,65) (was the row 0x01 alias)
code   0x05fb2e +4     select_wheel roster21: highlight base row 0x13 <- (217,77) (was the row 0x03 alias)
# select_wheel roster21: 3 highlight base rows written in place (32-row aliased pc-rel table 0x5fae2; the vs2 precedent — its variant half is un-aliased for its newcomers)
poke32 0x268a46 <- 0x2724a2  select_wheel roster21: p1 highlight row 0x11 = host row 0x0f ring (ring_rows)
poke32 0x268a4e <- 0x2724a2  select_wheel roster21: p1 highlight row 0x13 = host row 0x0f ring (ring_rows)
poke32 0x268ac6 <- 0x2726ce  select_wheel roster21: p2 highlight row 0x11 = host row 0x0f ring (ring_rows)
poke32 0x268ace <- 0x2726ce  select_wheel roster21: p2 highlight row 0x13 = host row 0x0f ring (ring_rows)
poke32 0x268b42 <- 0x2728e6  select_wheel roster21: mirror highlight row 0x10 = host row 0x0f ring (ring_rows)
poke32 0x268b46 <- 0x2728e6  select_wheel roster21: mirror highlight row 0x11 = host row 0x0f ring (ring_rows)
poke32 0x268b4e <- 0x2728e6  select_wheel roster21: mirror highlight row 0x13 = host row 0x0f ring (ring_rows)
# select_wheel roster21: 7 ring rows poked (host row 0x0f records verbatim; P1/P2 for non-tenant cells + mirror for all)
# select_wheel roster21: 3 cell outline sprites (4x3, pal 0x19 pen 0) at 0x1f800+ (rendered by build_gfx from the medallions' alpha)
code   0x05f8b2 +6     select_wheel roster21: drawer bank word #$2000 -> #$3000 (bank 5) in the select init — writes ONLY $FFB818 (measured)
# select_wheel roster21: 85 host + 18 vs2 tiles -> wheel_bank5.json (group C upper bank, placed by build_gfx --wheel-bank5)
data   0x3a3b20 +0x20  select_wheel roster21: medallion pal row 0x19 (cell 0x10) <- vs2 0x3bb19c; entry attr re-palmed
data   0x3a3b40 +0x20  select_wheel roster21: medallion pal row 0x1a (cell 0x11) <- vs2 0x3bb15c; entry attr re-palmed
data   0x3a3ac0 +0x20  select_wheel roster21: medallion pal row 0x16 (cell 0x13) <- vs2 0x3bafdc; entry attr re-palmed
code   0x0fdd50 +0x28  select_wheel roster21: march mid-row retarget 0x16/0x19 -> 0x02 (dest computation 0x2b598 jsr-routed)
code   0x0fdd80 +0x28  select_wheel roster21: march mid-row retarget 0x16/0x19 -> 0x02 (dest computation 0x2b7d8 jsr-routed)
data   0x41ed30 +0x1c  select_records portrait/p1 coord list (7 pairs, vs2 0x303238)
data   0x41ed50 +0x26  select_records portrait/p1 record (vs2 0x2a5e4a, 7 entries, budget 0x5b = vs2's own)
poke32 0x26746a <- 0x41ed50  select_records portrait/p1 array row 0x10 (was 0x271924, the base-half alias)
data   0x41ed80 +0x1c  select_records portrait/p2 coord list (7 pairs, vs2 0x3035a8)
data   0x41eda0 +0x26  select_records portrait/p2 record (vs2 0x2a625a, 7 entries, budget 0x5b = vs2's own)
poke32 0x2674ea <- 0x41eda0  select_records portrait/p2 array row 0x10 (was 0x271d36, the base-half alias)
data   0x41edd0 +0x4  select_records name_banner/p1 coord list (1 pairs, vs2 0x303730)
data   0x41ede0 +0xe  select_records name_banner/p1 record (vs2 0x2a64d6, 1 entries, budget 0x8 = vs2's own)
poke32 0x2675ea <- 0x41ede0  select_records name_banner/p1 array row 0x10 (was 0x272148, the base-half alias)
data   0x41edf0 +0x8  select_records name_banner/p2 coord list (2 pairs, vs2 0x303d9c)
data   0x41ee00 +0x12  select_records name_banner/p2 record (vs2 0x2a7506, 2 entries, budget 0x3 = vs2's own)
poke32 0x26766a <- 0x41ee00  select_records name_banner/p2 array row 0x10 (was 0x273052, the base-half alias)
data   0x41ee20 +0x14  select_records splash_p1/p1 coord list (5 pairs, vs2 0x304028)
data   0x41ee40 +0x1e  select_records splash_p1/p1 record (vs2 0x2a7b06, 5 entries, budget 0x4c = vs2's own)
poke32 0x2672ea <- 0x41ee40  select_records splash_p1/p1 array row 0x10 (was 0x273462, the base-half alias)
data   0x41ee60 +0x14  select_records splash_p2/p1 coord list (5 pairs, vs2 0x3042b8)
data   0x41ee80 +0x1e  select_records splash_p2/p1 record (vs2 0x2a7e36, 5 entries, budget 0x4c = vs2's own)
poke32 0x26736a <- 0x41ee80  select_records splash_p2/p1 array row 0x10 (was 0x2737a8, the base-half alias)
data   0x41eea0 +0x84  select_records win_quote/p1 coord list (33 pairs, vs2 0x304bd8)
data   0x41ef30 +0x8e  select_records win_quote/p1 record (vs2 0x2a881e, 33 entries, budget 0x8a = vs2's own)
poke32 0x2673ea <- 0x41ef30  select_records win_quote/p1 array row 0x10 (was 0x273aee, the base-half alias)
poke32 0x268a42 <- 0x2724a2  select_records highlight/p1 array row 0x10 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x272554)
poke32 0x268ac2 <- 0x2726ce  select_records highlight/p2 array row 0x10 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x272780)
# select_records: 0 bank-1 tile placements -> select_tiles.json (only the composed records' art; the slot-0x0F splash/win-quote families are NOT placed, so that Jedah art stays vanilla)
# select_records: 236 native bank-1 tiles -> select_bank5.json (copied vs2 -> group C bank 5 by build_gfx; the drawer's bank is thunk-gated per hover)
data   0x41efc0 +0x6040  win_pal_variant hui_win_pal: sparse block, 10 sets of 0xa0 at stride 0xaa0 (vs2 0x3c329c stride 0xb40)
code   0x0fddb0 +0x16  win_pal_variant thunk, 1-way: hui_win_pal d6==0x10 -> a0=0x41e5c0; else vanilla pool 0x3ad700
code   0x05f1b6 +6     win_pal_variant: movea.l #pool -> jsr 0xfddb0
code   0x0fddd0 +0x1a  site_thunk tenant_jump_seq; site 0x022a0e jmp-routed
code   0x0fddf0 +0xe  site_thunk shadow_seq_guard; site 0x08245c jmp-routed
code   0x0fde00 +0x1e  site_thunk name_bank_variant_id; site 0x05fce0 jsr-routed
code   0x0fde20 +0x1e  site_thunk splash_bank_variant_id; site 0x06c0e0 jsr-routed
code   0x0fde40 +0x16  site_thunk winquote_bank_variant_id; site 0x05f328 jsr-routed
data   0x425000 +0x140  site_thunk select_pal_variant_id data block <- vsav2 0x3c12dc
code   0x0fde60 +0x38  site_thunk select_pal_variant_id; site 0x05f146 jsr-routed
data   0x425140 +0x54  site_thunk throw_arc_tables data block <- vsav2 0x0279b4
data   0x4251a0 +0x370  site_thunk throw_arc_tables data block <- vsav2 0x027a08
code   0x0fdea0 +0x42  site_thunk throw_arc_tables; site 0x028386 jmp-routed
code   0x0fdef0 +0xe  site_thunk idmask_victim_spawn; site 0x060ef0 jmp-routed
code   0x0fdf00 +0x10  site_thunk idmask_piece_subtype; site 0x05e7d6 jmp-routed
data   0x425510 +0x100  site_thunk df_gold_variant_id data block <- vsav2 0x3abedc
code   0x0fdf10 +0x54  site_thunk df_gold_variant_id; site 0x02a8d6 jmp-routed
code   0x0fdf70 +0xfe  site_thunk beam_list_type6; site 0x01b6aa jmp-routed
code   0x0fe070 +0x1d6  site_thunk index_window_018468; site 0x018460 jmp-routed
code   0x0fe250 +0x5e  site_thunk hitclass_map_extend; site 0x01a888 jmp-routed
code   0x0fe2b0 +0x22  site_thunk voice_borrow_keep_tenant; site 0x00aef2 jsr-routed
code   0x0fe2e0 +0x1e  site_thunk oboro_select_hook; site 0x020b9c jsr-routed
code   0x0282f4 +0x2  code_word obj_bank_word_slot (slot entry -> 1000)
code   0x05f240 +0x2  code_word win_pos_x_slot (slot entry -> 00c0)
code   0x05f242 +0x2  code_word win_pos_y_slot (slot entry -> 0080)
code   0x02a8c4 +0x2  code_word df_seq_entry_10 (slot entry -> 0032)
code   0x00aef8 +0x2  code_word voice_borrow_site_pad (0382 -> 4e71)
code   0x003bee +0x2  code_word hui_kernel_voice_e0 (01d0 -> 01a2)
code   0x003c5a +0x2  code_word hui_kernel_voice_e1 (01d1 -> 02a1)
code   0x003cc6 +0x2  code_word hui_kernel_voice_e2 (01d2 -> 02a2)
code   0x003d30 +0x2  code_word hui_kernel_voice_e3 (01d3 -> 01c1)
code   0x080aec +0x4  code_ptr beam_effect_class16 (00080b44 -> 000d8ab0 = x093460+0x0)
code   0x080b28 +0x4  code_ptr beam_effect_class31 (00080b44 -> 000d89b0 = x0926e4+0x0)
# M5: sfx helper 0x5122 UN-STUBBED -> vsavj 0x5fff00 (record array hui_sfx_records is placed)
# image: extend to 0x600000 (4 x 0x80000 member(s): vsw.41, vsw.42, vsw.43, vsw.44)
