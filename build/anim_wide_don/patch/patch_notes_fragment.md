# donovan-m2 stage 6 — generated op notes

# stage 1: Jedah hitbox block 0x09755E+0x0 (base 0x9769e comp 0x9755e)
# table_fix: region x026142 len 0x1400 -> 0x1440 (ported per-char OBJ bank table -> vanilla vsavj values (0x282D4))
# layout group at 0xbf6a0+0xdcec: code@0xbf6a0, x05c800@0xc2a10, x065952@0xcbb62, x065c22@0xcbe32, x065e5a@0xcc06a, x066ec4@0xcd0d4; 0x29ec gap bytes recycled
# layout group at 0xcd390+0x2de0: x026142@0xcd390, x028122@0xcf370; 0x358c gap bytes recycled
# anim: gfx_remap +0x2750 on 13418 band tile words, 223 exception words, 1123 effect words (237 blocks pooled; 775 band srcs skipped; 358 protected) in 1160 records
data_file 0x400010 +0x20f00  donovan anim (from vsav2 0x27F548)
data_file 0x0c9410 +0xf10  donovan aux0_0 (from vsav2 0x334B80)
data_file 0x0ca320 +0x190  donovan aux0_1 (from vsav2 0x337460)
data_file 0x0ca4b0 +0x1a0  donovan aux0_2 (from vsav2 0x33CCF0)
data_file 0x0ca650 +0x190  donovan aux0_3 (from vsav2 0x34CB60)
data_file 0x3ec720 +0xe070  donovan aux0_4 (from vsav2 0x352120)
code   0x0cb7e0 slot-clearing alloc wrapper for 0x15702 -> 0x16fba (0x80 cleared, +8 preserved)
code   0x0c2a00 farm-port stub for 0x2916c (param at 0x0cb810, common 0x29f4a)
code   0x0cb840 farm-port stub for 0x2915c (param at 0x0cb830, common 0x29f4a)
code   0x0cb860 farm-port stub for 0x29164 (param at 0x0cb850, common 0x29f4a)
code   0x0cb880 farm-port stub for 0x29184 (param at 0x0cb870, common 0x29f4a)
code   0x0cb8a0 farm-port stub for 0x2918c (param at 0x0cb890, common 0x29f4a)
code   0x0cb8b0 slot-clearing alloc wrapper for 0x1572e -> 0x16fe6 (0x80 cleared, +8 preserved)
code   0x0cb8e0 ILLEGAL  TRIPWIRE for unresolved 0x4223c
# code+0x1b08: unresolved 0x4223c -> tripwire 0xcb8e0
code   0x0cb8f0 ILLEGAL  TRIPWIRE for unresolved 0x42cee
# code+0x21e0: unresolved 0x42cee -> tripwire 0xcb8f0
code   0x0cb900 ILLEGAL  TRIPWIRE for unresolved 0x448d4
# code+0x3092: unresolved 0x448d4 -> tripwire 0xcb900
code_file 0x0bf6a0 +0x3200  donovan code (from vsav2 0x059490)
# hitbox+0x11a9: region_fix 4e -> 06 (sworded deity hit 1/7: type 0x4E -> 0x06 (vs2 dispatch alias — class-8 native electric))
# hitbox+0x11c9: region_fix 4e -> 06 (sworded deity hit 2/7: type 0x4E -> 0x06 (vs2 dispatch alias — class-8 native electric))
# hitbox+0x11e9: region_fix 4e -> 06 (sworded deity hit 3/7: type 0x4E -> 0x06 (vs2 dispatch alias — class-8 native electric))
# hitbox+0x1209: region_fix 4e -> 06 (sworded deity hit 4/7: type 0x4E -> 0x06 (vs2 dispatch alias — class-8 native electric))
# hitbox+0x1229: region_fix 4e -> 06 (sworded deity hit 5/7: type 0x4E -> 0x06 (vs2 dispatch alias — class-8 native electric))
# hitbox+0x1249: region_fix 4e -> 06 (sworded deity hit 6/7: type 0x4E -> 0x06 (vs2 dispatch alias — class-8 native electric))
# hitbox+0x1269: region_fix 4e -> 06 ()
# hitbox+0x1289: region_fix 4e -> 06 (ES-variant deity record type 0x4E -> 0x06 (14z-44; vs2-alias-proven, the 14z-36 pattern))
# hitbox+0x12a9: region_fix 4e -> 06 (ES-variant deity record type 0x4E -> 0x06 (14z-44; vs2-alias-proven, the 14z-36 pattern))
# hitbox+0x12c9: region_fix 4e -> 06 (ES-variant deity record type 0x4E -> 0x06 (14z-44; vs2-alias-proven, the 14z-36 pattern))
# hitbox+0x12e9: region_fix 4e -> 06 (ES-variant deity record type 0x4E -> 0x06 (14z-44; vs2-alias-proven, the 14z-36 pattern))
# hitbox+0x1309: region_fix 4e -> 06 (ES-variant deity record type 0x4E -> 0x06 (14z-44; vs2-alias-proven, the 14z-36 pattern))
# hitbox+0x1329: region_fix 4e -> 06 (ES-variant deity record type 0x4E -> 0x06 (14z-44; vs2-alias-proven, the 14z-36 pattern))
# hitbox+0x1349: region_fix 4e -> 06 (ES-variant deity record type 0x4E -> 0x06 (14z-44; vs2-alias-proven, the 14z-36 pattern))
data_file 0x3fa790 +0x25c2  donovan hitbox (from vsav2 0x0C8BB8)
# hitbox_proj+0x291: region_fix 52 -> 06 (column KO record type 0x52 -> 0x06 (vs2 dispatch alias; vsavj table ends at 0x4F -> wild jump))
# hitbox_proj+0x2b1: region_fix 52 -> 06 (column sibling hit record, same type-0x52 alias remap (would crash on its own kill timing))
# hitbox_proj+0x2d1: region_fix 52 -> 06 (column sibling hit record, same type-0x52 alias remap (would crash on its own kill timing))
# hitbox_proj+0x131: region_fix 50 -> 0f (extended record type 0x50 -> 0x0F (vs2 dispatch alias: entry 0x50 word 0x16E == entry 0x0F's; same wild-jump class past vsavj's 0x4F table end))
# hitbox_proj+0x151: region_fix 50 -> 0f (extended record type 0x50 -> 0x0F (vs2 dispatch alias: entry 0x50 word 0x16E == entry 0x0F's; same wild-jump class past vsavj's 0x4F table end))
# hitbox_proj+0x2f1: region_fix 50 -> 0f (extended record type 0x50 -> 0x0F (vs2 dispatch alias: entry 0x50 word 0x16E == entry 0x0F's; same wild-jump class past vsavj's 0x4F table end))
# hitbox_proj+0x311: region_fix 50 -> 0f (extended record type 0x50 -> 0x0F (vs2 dispatch alias: entry 0x50 word 0x16E == entry 0x0F's; same wild-jump class past vsavj's 0x4F table end))
# hitbox_proj+0x331: region_fix 50 -> 0f (extended record type 0x50 -> 0x0F (vs2 dispatch alias: entry 0x50 word 0x16E == entry 0x0F's; same wild-jump class past vsavj's 0x4F table end))
# hitbox_proj+0x351: region_fix 50 -> 0f (extended record type 0x50 -> 0x0F (vs2 dispatch alias: entry 0x50 word 0x16E == entry 0x0F's; same wild-jump class past vsavj's 0x4F table end))
data_file 0x0ca7e0 +0x1000  donovan hitbox_proj (from vsav2 0x0D0CA8)
# x026142+0x1414: bank table row 0x13 <- 0x1000 (bank 4, WIDE encoding; vanilla row was 0x2000) — tenant-driven
# x026142+0x13ee: table_fix 48 bytes (ported per-char OBJ bank table -> vanilla vsavj values (0x282D4))
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
code_file 0x0cd390 +0x1440  donovan x026142 (from vsav2 0x026142)
# bank_ref 0xd6ebe -> 0xbcd20 (delta rule, 16B byte-identical)
# bank_ref 0xd699e -> 0xbc800 (delta rule, 16B byte-identical)
# bank_ref 0xd671e -> 0xbc580 (delta rule, 16B byte-identical)
# bank_ref 0xd671e -> 0xbc580 (delta rule, 16B byte-identical)
# bank_ref 0xd679e -> 0xbc600 (delta rule, 16B byte-identical)
# bank_ref 0xd679e -> 0xbc600 (delta rule, 16B byte-identical)
# x028122+0x9a0: port_patch 3b7c0001b498 -> 3b7c0001b446 (throw dmg: flag var -> vsavj layout (-0x4BBA))
# x028122+0x9a6: port_patch 426db494 -> 426db442 (throw dmg: clr damage var -> vsavj layout (-0x4BBE))
# x028122+0x9b6: port_patch 3b42b494 -> 3b42b442 (throw dmg: scaled damage -> vsavj layout (-0x4BBE))
# x028122+0x9ba: port_patch 3b7c0000b498 -> 3b7c0000b446 (throw dmg: flag clear -> vsavj layout (-0x4BBA))
# x028122+0x9c0: port_patch 426db496 -> 426db444 (throw dmg: clr white var -> vsavj layout (-0x4BBC))
# x028122+0x9d0: port_patch 3b42b496 -> 3b42b444 (throw dmg: white damage -> vsavj layout (-0x4BBC))
code_file 0x0cf370 +0xe00  donovan x028122 (from vsav2 0x028122)
code   0x0cb910 ILLEGAL  TRIPWIRE for unresolved 0x12f484
# x05c800+0x152a: unresolved 0x12f484 -> tripwire 0xcb910
# x05c800+0x16a4: unresolved 0x12f484 -> tripwire 0xcb910
code   0x0cb920 ILLEGAL  TRIPWIRE for unresolved 0x167bf4
# x05c800+0x2622: unresolved 0x167bf4 -> tripwire 0xcb920
# x05c800+0x2a20: unresolved 0x167bf4 -> tripwire 0xcb920
code   0x0cb930 ILLEGAL  TRIPWIRE for unresolved 0x17f176
# x05c800+0x2ae4: unresolved 0x17f176 -> tripwire 0xcb930
# x05c800+0x3034: unresolved 0x17f176 -> tripwire 0xcb930
code   0x0cb940 ILLEGAL  TRIPWIRE for unresolved 0x181592
# x05c800+0x3072: unresolved 0x181592 -> tripwire 0xcb940
# x05c800+0x738: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 (Jedah band) / WIDE bank 4)
# x05c800+0x58d4: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (a4 form): vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x05c800+0x5994: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (a4 form): vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
code_file 0x0c2a10 +0x6a00  donovan x05c800 (from vsav2 0x05C800)
code_file 0x0cbb62 +0x2d0  donovan x065952 (from vsav2 0x065952)
code_file 0x0cbe32 +0x100  donovan x065c22 (from vsav2 0x065C22)
code   0x0cb950 +0x40  patched clone of 0x5459a for vs2 0x5c77e (unmasked set-anim entry; false byte-matc)
code_file 0x0cc06a +0x106a  donovan x065e5a (from vsav2 0x065E5A)
code_file 0x0cd0d4 +0x2b8  donovan x066ec4 (from vsav2 0x066EC4)
code_file 0x0c28a0 +0x154  donovan x06717c (from vsav2 0x06717C)
code   0x0cb990 ILLEGAL  TRIPWIRE for unresolved 0x24edd4
# x088512+0x1362: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x13a0: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x13e4: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x1428: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x1464: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x14a2: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x150a: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x154e: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x1590: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x15f0: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x1670: unresolved 0x24edd4 -> tripwire 0xcb990
code   0x0cb9a0 ILLEGAL  TRIPWIRE for unresolved 0x24a3ce
# x088512+0x16d8: unresolved 0x24a3ce -> tripwire 0xcb9a0
# x088512+0x1732: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x1796: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x17fa: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x18ee: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x191c: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x194a: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x1994: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x1cd2: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x1d1a: unresolved 0x24edd4 -> tripwire 0xcb990
code   0x0cb9b0 ILLEGAL  TRIPWIRE for unresolved 0x36784a
# x088512+0x1dee: unresolved 0x36784a -> tripwire 0xcb9b0
code   0x0cb9c0 ILLEGAL  TRIPWIRE for unresolved 0x25111e
# x088512+0x2156: unresolved 0x25111e -> tripwire 0xcb9c0
# x088512+0x21d2: unresolved 0x25111e -> tripwire 0xcb9c0
# x088512+0x26e2: unresolved 0x25111e -> tripwire 0xcb9c0
code   0x0cb9d0 ILLEGAL  TRIPWIRE for unresolved 0x2695d0
# x088512+0x2894: unresolved 0x2695d0 -> tripwire 0xcb9d0
# x088512+0x28ce: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x290c: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x294a: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x2986: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x29c4: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x2a2c: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x2a6a: unresolved 0x24edd4 -> tripwire 0xcb990
# x088512+0x209c: char-id imm 0x13 -> 0x13
code   0x0cead0 ILLEGAL  shared pcrel TRIPWIRE for x088512
# x088512: 9 pcrel escape entries rewritten (tripwire at 0xcead0)
# x088512+0x2be6: port_patch 000e -> 000c (companion queue class 7 (vs2-only) -> vsavj class 6)
# x088512+0x22c: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x088512+0x1814: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x088512+0x2bee: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
code_file 0x0d0170 +0x2f00  donovan x088512 (from vsav2 0x088512)
code   0x0ceae0 ILLEGAL  shared pcrel TRIPWIRE for x0905ae
# x0905ae: 2 pcrel escape entries rewritten (tripwire at 0xceae0)
code_file 0x0ce7d0 +0x300  donovan x0905ae (from vsav2 0x0905AE)
code   0x0cb9e0 ILLEGAL  TRIPWIRE for unresolved 0x2c3136
# x2b7ef4+0xb0c9: unresolved 0x2c3136 -> tripwire 0xcb9e0
code   0x0cb9f0 ILLEGAL  TRIPWIRE for unresolved 0x2c3170
# x2b7ef4+0xb0d1: unresolved 0x2c3170 -> tripwire 0xcb9f0
code   0x0cba00 ILLEGAL  TRIPWIRE for unresolved 0x2c31aa
# x2b7ef4+0xb0d9: unresolved 0x2c31aa -> tripwire 0xcba00
code   0x0cba10 ILLEGAL  TRIPWIRE for unresolved 0x2c31e4
# x2b7ef4+0xb0fd: unresolved 0x2c31e4 -> tripwire 0xcba10
code   0x0cba20 ILLEGAL  TRIPWIRE for unresolved 0x2c3236
# x2b7ef4+0xb105: unresolved 0x2c3236 -> tripwire 0xcba20
code   0x0cba30 ILLEGAL  TRIPWIRE for unresolved 0x2c325c
# x2b7ef4+0xb10d: unresolved 0x2c325c -> tripwire 0xcba30
code   0x0cba40 ILLEGAL  TRIPWIRE for unresolved 0x2c3272
# x2b7ef4+0xb115: unresolved 0x2c3272 -> tripwire 0xcba40
code   0x0cba50 ILLEGAL  TRIPWIRE for unresolved 0x2c3280
# x2b7ef4+0xb11d: unresolved 0x2c3280 -> tripwire 0xcba50
code   0x0cba60 ILLEGAL  TRIPWIRE for unresolved 0x2c3296
# x2b7ef4+0xb125: unresolved 0x2c3296 -> tripwire 0xcba60
code   0x0cba70 ILLEGAL  TRIPWIRE for unresolved 0x2c32a4
# x2b7ef4+0xb12d: unresolved 0x2c32a4 -> tripwire 0xcba70
code   0x0cba80 ILLEGAL  TRIPWIRE for unresolved 0x2c32b2
# x2b7ef4+0xb135: unresolved 0x2c32b2 -> tripwire 0xcba80
# x2b7ef4: effect_tail — 128 bank-1 words, 308 bank-2 words (tail placements), 114 coord lists matched, 617 ported (11336B fragment)
data_file 0x0d3070 +0xb20c  donovan x2b7ef4 (from vsav2 0x2B7EF4)
data     0x0ceaf0 +0x500  sprite palette block (vsav2 0x39CB9C); poke32 0x38c1e4 (table 0x38c198 row 0x13)
data     0x0de280 +0xdc0  effect palette block (vsav2 0x3ADFDC); poke32 0x38c264 (table 0x38c218 row 0x13)
poke32 0x0bcec6 <- 0x00400010  anim_index_a[0x13] donovan anim
poke32 0x0bcf46 <- 0x0040215e  anim_index_a2[0x13] donovan anim
poke32 0x0bcfc6 <- 0x00407b64  anim_index_b[0x13] donovan anim
poke32 0x0bd046 <- 0x00407c5a  anim_index_c[0x13] donovan anim
poke32 0x0bd0c6 <- 0x0040a9be  anim_index_proj[0x13] donovan anim
# param32_a: velocity pair NOT ported (14w-b crash guard; Jedah speeds retained)
# jump_params: velocity pair NOT ported (14w-b crash guard; Jedah speeds retained)
poke32 0x0bd9c6 <- 0x003fa9d0  hitbox_base[0x13] donovan hitbox
poke32 0x0bda46 <- 0x003fa790  hitbox_comp[0x13] donovan hitbox
poke32 0x0bdac6 <- 0x000ca7e0  proj_hitbox_base[0x13] donovan hitbox_proj
poke32 0x0bdb46 <- 0x000cab3a  proj_hitbox_comp[0x13] donovan hitbox_proj
data   0x0bdc12 +0x8  rec8_a[0x13] value
data   0x0be1a0 +0x2  word132[0x13] value
data   0x0be1e0 +0x2  word_pos_a[0x13] value
data   0x0be220 +0x2  word_pos_b[0x13] value
# param32_b: velocity pair NOT ported (14w-b crash guard; Jedah speeds retained)
data   0x0be492 +0x8  rec8_b[0x13] value
data   0x0be820 +0x2  word_y_off[0x13] value
data   0x0be860 +0x2  word_range[0x13] value
data   0x0be88c +0x2  byte15b[0x13] value
data   0x0bead4 +0x1e  byte2d_a[0x13] value
data   0x0bee94 +0x1e  byte2d_b[0x13] value
poke32 0x0bf2e6 <- 0x000bfcec  tail_code_ptr[0x13] donovan code
# tail_data_ptr: ptr row owned by sound_table don_sfx_records — generic repoint suppressed (14z-65)
code   0x0cba90 ILLEGAL  TRIPWIRE for unresolved 0x672d0
# obj_hook@0x54470 type 64: unresolved 0x672d0 -> tripwire 0xcba90
code   0x0cbaa0 ILLEGAL  TRIPWIRE for unresolved 0x67550
# obj_hook@0x54470 type 65: unresolved 0x67550 -> tripwire 0xcbaa0
code   0x0cbab0 ILLEGAL  TRIPWIRE for unresolved 0x67846
# obj_hook@0x54470 type 66: unresolved 0x67846 -> tripwire 0xcbab0
code   0x0cbac0 ILLEGAL  TRIPWIRE for unresolved 0x67a00
# obj_hook@0x54470 type 67: unresolved 0x67a00 -> tripwire 0xcbac0
code   0x0cbad0 ILLEGAL  TRIPWIRE for unresolved 0x6800c
# obj_hook@0x54470 type 68: unresolved 0x6800c -> tripwire 0xcbad0
code   0x0cbae0 ILLEGAL  TRIPWIRE for unresolved 0x68458
# obj_hook@0x54470 type 69: unresolved 0x68458 -> tripwire 0xcbae0
code   0x0cbaf0 ILLEGAL  TRIPWIRE for unresolved 0x68768
# obj_hook@0x54470 type 70: unresolved 0x68768 -> tripwire 0xcbaf0
code   0x0cbb00 ILLEGAL  TRIPWIRE for unresolved 0x689cc
# obj_hook@0x54470 type 71: unresolved 0x689cc -> tripwire 0xcbb00
code   0x0cbb10 ILLEGAL  TRIPWIRE for unresolved 0x68c78
# obj_hook@0x54470 type 72: unresolved 0x68c78 -> tripwire 0xcbb10
code   0x0cbb20 ILLEGAL  TRIPWIRE for unresolved 0x69046
# obj_hook@0x54470 type 73: unresolved 0x69046 -> tripwire 0xcbb20
code   0x0cbb30 ILLEGAL  TRIPWIRE for unresolved 0x692f6
# obj_hook@0x54470 type 74: unresolved 0x692f6 -> tripwire 0xcbb30
code   0x0cbb40 ILLEGAL  TRIPWIRE for unresolved 0x6965e
# obj_hook@0x54470 type 75: unresolved 0x6965e -> tripwire 0xcbb40
data   0x0ceff0 +0x130  proj_hook extended type table (59 vanilla + 17 ported, 5 placed)
code   0x0cbb50 obj_hook thunk (ghost-clean: returns to vanilla jsr)
code   0x054470 ENGINE HOOK: dispatch -> jmp thunk; vanilla jsr (A0) at 0x54476 untouched (vanilla types identical via table copy)
code   0x0cbf40 ILLEGAL  TRIPWIRE for unresolved 0x6a70c
# obj_hook@0x5e542 type 121: unresolved 0x6a70c -> tripwire 0xcbf40
# obj_hook@0x5e542 type 122: unresolved 0x6a70c -> tripwire 0xcbf40
# obj_hook@0x5e542 type 123: unresolved 0x6a70c -> tripwire 0xcbf40
data   0x0cf120 +0x1f0  proj_hook extended type table (114 vanilla + 10 ported, 7 placed)
code   0x0cbf50 obj_hook thunk (ghost-clean: returns to vanilla jsr)
code   0x05e542 ENGINE HOOK: dispatch -> jmp thunk; vanilla jsr (A0) at 0x5e548 untouched (vanilla types identical via table copy)
data   0x3ff9b0 +0x180  state_hook palette-seq records (ids 0x2cd-0x2d8)
code   0x0cbf70 state_hook private seq entry (records base 0x3ff9b0 - 0x2cd*32 -> engine 0x2ad9a)
code   0x02a7c8 ENGINE HOOK: +0x14e state dispatch -> thunk 0x0cbfb0 (vanilla ids ghost-clean via jmp-back; ids 0xb2-0xc8 -> 12 synthesized stubs at 0x0df040, ext table 0x0cbf80)
code   0x018458 ENGINE HOOK: hit-reaction dispatch -> thunk 0x0cc030 (vanilla ids jmp back to untouched 0x18460; ids 0xa0-0xa6 -> 4 verbatim vs2 cases at 0x0cbff0)
code   0x0cf310 init shim (pool latch A5+0x7966, seeder 0x16c64; flavor (A6+0x3c2) donovan<-0x01/held 0x00 [Start bitmask 0xff8060, bit=player]) -> handler 0x0c1030
poke32 0x0bd146 <- 0x000cf310  dispatch_00[0x13] donovan handler via seed shim
poke32 0x0bd1c6 <- 0x000bf6aa  dispatch_01[0x13] donovan handler
poke32 0x0bd246 <- 0x000bff64  dispatch_02[0x13] donovan handler
poke32 0x0bd2c6 <- 0x000bff64  dispatch_03[0x13] donovan handler
poke32 0x0bd346 <- 0x000bff64  dispatch_04[0x13] donovan handler
poke32 0x0bd3c6 <- 0x000c0a12  dispatch_05[0x13] donovan handler
poke32 0x0bd446 <- 0x000bfa9c  dispatch_06[0x13] donovan handler
poke32 0x0bd4c6 <- 0x000c0cb0  dispatch_07[0x13] donovan handler
poke32 0x0bd546 <- 0x000bfb30  dispatch_08[0x13] donovan handler
poke32 0x0bd5c6 <- 0x000bfc32  dispatch_09[0x13] donovan handler
poke32 0x0bd646 <- 0x000bf9d2  dispatch_10[0x13] donovan handler
poke32 0x0bd6c6 <- 0x000c0dfa  dispatch_11[0x13] donovan handler
poke32 0x0bd746 <- 0x000c0f9c  dispatch_12[0x13] donovan handler
poke32 0x0bd7c6 <- 0x000c0fe6  dispatch_13[0x13] donovan handler
poke32 0x0bd846 <- 0x000c0d74  dispatch_14[0x13] donovan handler
poke32 0x0bf266 <- 0x000bfb54  dispatch_15[0x13] donovan handler
poke32 0x0bf366 <- 0x000c109c  dispatch_16[0x13] donovan handler
poke32 0x0bf3e6 <- 0x000c10d8  dispatch_17[0x13] donovan handler
poke32 0x0bf4e6 <- 0x000c1124  dispatch_18[0x13] donovan handler
poke32 0x0bf666 <- 0x000c1106  dispatch_19[0x13] donovan handler
# aux hud_name_entry_0f_hi: SKIPPED (host-slot content; tenant is at variant id 0x13)
# aux hud_name_entry_0f_lo: SKIPPED (host-slot content; tenant is at variant id 0x13)
poke16 0x0898aa <- 0x8690  aux hud_mug_entry_13
poke32 0x08995c <- 0x868c0202  aux hud_name_entry_13_hi
poke32 0x089960 <- 0xffe80003  aux hud_name_entry_13_lo
data   0x420f10 +0xe50  data_port throw_victim_keyframes PLACED (tenant at 0x13; host block 0xb19f8 untouched) <- vsav2 0x0ca1ca (1 fixes)
poke32 0x0be2c6 <- 0x420f10  data_port throw_victim_keyframes ptr-table 0xbe27a row 0x13
# data_port weapon_accent_t0: SKIPPED (host-slot content; tenant is at variant id 0x13)
# data_port weapon_accent_t1: SKIPPED (host-slot content; tenant is at variant id 0x13)
# data_port weapon_accent_rowd_slot: SKIPPED (host-slot content; tenant is at variant id 0x13)
data   0x028d50 +0x4  data_port hit_class_props_ext_hi <- vsav2 0x028028 (0 fixes)
data   0x028d4e +0x2  data_port hit_class_props_ext_lo <- vsav2 0x028026 (0 fixes)
# data_port win_pal_slot0f_c0: SKIPPED (host-slot content; tenant is at variant id 0x13)
# data_port win_pal_slot0f_c1: SKIPPED (host-slot content; tenant is at variant id 0x13)
# data_port win_pal_slot0f_c2: SKIPPED (host-slot content; tenant is at variant id 0x13)
# data_port win_pal_slot0f_c3: SKIPPED (host-slot content; tenant is at variant id 0x13)
# data_port win_pal_slot0f_c4: SKIPPED (host-slot content; tenant is at variant id 0x13)
# data_port win_pal_slot0f_c5: SKIPPED (host-slot content; tenant is at variant id 0x13)
# data_port win_pal_slot0f_c6: SKIPPED (host-slot content; tenant is at variant id 0x13)
# data_port win_pal_slot0f_c7: SKIPPED (host-slot content; tenant is at variant id 0x13)
# data_port med_pal_row14_a: SKIPPED (host-slot content; tenant is at variant id 0x13)
data   0x421d60 +0x160  sound_table don_sfx_records <- vsav2 0x0cb01a (44 entries; kept ['0x110@1', '0x111@2', '0x112@3', '0x152@21', '0x119@22']; zeroed 38 unplayable ids)
poke32 0x0bf466 <- 0x421d60  sound_table don_sfx_records per-char ptr row 0x13 (was 0x9a630)
data   0x0211e4        select_wheel roster21: TABLE B in place, 28 bytes over 3 new rows + 5 inbound edges
data   0x421ec0 +0x54  select_wheel roster21 coord list (18 vanilla + 3 new)
data   0x421f20 +0x5e  select_wheel roster21 record (count 17->20, budget 0x55 CARRIED OVER, cptr -> 0x421ec0)
poke32 0x2689fe <- 0x421f20  select_wheel roster21 record ptr (was 0x272a68; the record's ONLY referrer — vanilla record and list are untouched)
code   0x05fb22 +4     select_wheel roster21: highlight base row 0x10 <- (158,80) (was the row 0x00 alias)
code   0x05fb26 +4     select_wheel roster21: highlight base row 0x11 <- (188,72) (was the row 0x01 alias)
code   0x05fb2e +4     select_wheel roster21: highlight base row 0x13 <- (216,80) (was the row 0x03 alias)
# select_wheel roster21: 3 highlight base rows written in place (32-row aliased pc-rel table 0x5fae2; the vs2 precedent — its variant half is un-aliased for its newcomers)
poke32 0x268a42 <- 0x2724a2  select_wheel roster21: p1 highlight row 0x10 = host row 0x0f ring (ring_rows)
poke32 0x268a46 <- 0x2724a2  select_wheel roster21: p1 highlight row 0x11 = host row 0x0f ring (ring_rows)
poke32 0x268ac2 <- 0x2726ce  select_wheel roster21: p2 highlight row 0x10 = host row 0x0f ring (ring_rows)
poke32 0x268ac6 <- 0x2726ce  select_wheel roster21: p2 highlight row 0x11 = host row 0x0f ring (ring_rows)
poke32 0x268b42 <- 0x2728e6  select_wheel roster21: mirror highlight row 0x10 = host row 0x0f ring (ring_rows)
poke32 0x268b46 <- 0x2728e6  select_wheel roster21: mirror highlight row 0x11 = host row 0x0f ring (ring_rows)
poke32 0x268b4e <- 0x2728e6  select_wheel roster21: mirror highlight row 0x13 = host row 0x0f ring (ring_rows)
# select_wheel roster21: 7 ring rows poked (host row 0x0f records verbatim; P1/P2 for non-tenant cells + mirror for all)
code   0x05f8b2 +6     select_wheel roster21: drawer bank word #$2000 -> #$3000 (bank 5) in the select init — writes ONLY $FFB818 (measured)
# select_wheel roster21: 85 host + 18 vs2 tiles -> wheel_bank5.json (group C upper bank, placed by build_gfx --wheel-bank5)
data   0x3a3b20 +0x20  select_wheel roster21: medallion pal row 0x19 (cell 0x10) <- vs2 0x3bb19c; entry attr re-palmed
data   0x3a3b40 +0x20  select_wheel roster21: medallion pal row 0x1a (cell 0x11) <- vs2 0x3bb15c; entry attr re-palmed
data   0x3a3ac0 +0x20  select_wheel roster21: medallion pal row 0x16 (cell 0x13) <- vs2 0x3bafdc; entry attr re-palmed
code   0x0df1c0 +0x28  select_wheel roster21: march mid-row retarget 0x16/0x19 -> 0x02 (dest computation 0x2b598 jsr-routed)
code   0x0df1f0 +0x28  select_wheel roster21: march mid-row retarget 0x16/0x19 -> 0x02 (dest computation 0x2b7d8 jsr-routed)
data   0x421f80 +0x1c  select_records portrait/p1 coord list (7 pairs, vs2 0x3036f8)
data   0x421fa0 +0x26  select_records portrait/p1 record (vs2 0x2a63f0, 7 entries, budget 0x5b = vs2's own)
poke32 0x267476 <- 0x421fa0  select_records portrait/p1 array row 0x13 (was 0x2719da, the base-half alias)
data   0x421fd0 +0x1c  select_records portrait/p2 coord list (7 pairs, vs2 0x303714)
data   0x421ff0 +0x26  select_records portrait/p2 record (vs2 0x2a6416, 7 entries, budget 0x5b = vs2's own)
poke32 0x2674f6 <- 0x421ff0  select_records portrait/p2 array row 0x13 (was 0x271dec, the base-half alias)
data   0x0cf360 +0x4  select_records name_banner/p1 coord list (1 pairs, vs2 0x303734)
data   0x422020 +0xe  select_records name_banner/p1 record (vs2 0x2a657e, 1 entries, budget 0xa = vs2's own)
poke32 0x2675f6 <- 0x422020  select_records name_banner/p1 array row 0x13 (was 0x272172, the base-half alias)
data   0x422030 +0x8  select_records name_banner/p2 coord list (2 pairs, vs2 0x303da4)
data   0x422040 +0x12  select_records name_banner/p2 record (vs2 0x2a76a4, 2 entries, budget 0x3 = vs2's own)
poke32 0x267676 <- 0x422040  select_records name_banner/p2 array row 0x13 (was 0x273080, the base-half alias)
data   0x422060 +0x14  select_records splash_p1/p1 coord list (5 pairs, vs2 0x3043a4)
data   0x422080 +0x1e  select_records splash_p1/p1 record (vs2 0x2a7f68, 5 entries, budget 0x4b = vs2's own)
poke32 0x2672f6 <- 0x422080  select_records splash_p1/p1 array row 0x13 (was 0x2734e8, the base-half alias)
data   0x4220a0 +0x14  select_records splash_p2/p1 coord list (5 pairs, vs2 0x3043b8)
data   0x4220c0 +0x1e  select_records splash_p2/p1 record (vs2 0x2a7f86, 5 entries, budget 0x4b = vs2's own)
poke32 0x267376 <- 0x4220c0  select_records splash_p2/p1 array row 0x13 (was 0x27382e, the base-half alias)
data   0x4220e0 +0x8c  select_records win_quote/p1 coord list (35 pairs, vs2 0x30506c)
data   0x422170 +0x96  select_records win_quote/p1 record (vs2 0x2a8cf8, 35 entries, budget 0xa7 = vs2's own)
poke32 0x2673f6 <- 0x422170  select_records win_quote/p1 array row 0x13 (was 0x273d3c, the base-half alias)
poke32 0x268a4e <- 0x2724a2  select_records highlight/p1 array row 0x13 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x272594)
poke32 0x268ace <- 0x2726ce  select_records highlight/p2 array row 0x13 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x2727c0)
# select_records: 0 bank-1 tile placements -> select_tiles.json (only the composed records' art; the slot-0x0F splash/win-quote families are NOT placed, so that Jedah art stays vanilla)
# select_records: 271 native bank-1 tiles -> select_bank5.json (copied vs2 -> group C bank 5 by build_gfx; the drawer's bank is thunk-gated per hover)
data   0x422210 +0x4b00  win_pal_variant don_win_pal: sparse block, 8 sets of 0xa0 at stride 0xaa0 (vs2 0x3c365c stride 0xb40)
code   0x0df220 +0x16  win_pal_variant don_win_pal thunk (d6==TT -> a0 = 0x421630; else vanilla pool 0x3ad700)
code   0x05f1b6 +6     win_pal_variant don_win_pal: movea.l #pool -> jsr 0xdf220
code   0x3ffb30 +0x62  site_thunk fixture_row0f_override_bank0; site 0x01c586 jsr-routed
code   0x3ffba0 +0x62  site_thunk fixture_row0f_override_bank1; site 0x01c59a jsr-routed
code   0x0df240 +0x18  site_thunk select_companion_tbl_a; site 0x0845ec jsr-routed
code   0x0df260 +0x18  site_thunk select_companion_tbl_b; site 0x0845f8 jsr-routed
code   0x0df280 +0x22  site_thunk select_companion_resolve_s1; site 0x084602 jsr-routed
code   0x0df2b0 +0x22  site_thunk select_companion_resolve_s2; site 0x084624 jsr-routed
code   0x0df2e0 +0x3c  site_thunk accent_color_aware_0; site 0x02ad82 jsr-routed
code   0x0df320 +0x3c  site_thunk accent_color_aware_1; site 0x02ad94 jsr-routed
code   0x0df360 +0x3c  site_thunk accent_color_aware_2; site 0x02b342 jsr-routed
code   0x0df3a0 +0x3c  site_thunk accent_color_aware_3; site 0x02b7e8 jsr-routed
code   0x0df3e0 +0x2a  site_thunk ls_freeze_vs2_victim; site 0x023ad8 jsr-routed
code   0x0df410 +0x24  site_thunk ls_freeze_vs2_attacker; site 0x023ade jsr-routed
code   0x0df440 +0x16  site_thunk es_type51_dispatch; site 0x0185ca jsr-routed
code   0x0df460 +0x1e  site_thunk name_bank_variant_id; site 0x05fce0 jsr-routed
code   0x0df480 +0x1e  site_thunk splash_bank_variant_id; site 0x06c0e0 jsr-routed
code   0x0df4a0 +0x16  site_thunk winquote_bank_variant_id; site 0x05f328 jsr-routed
code   0x0df4c0 +0x7e  site_thunk select_sword_pal_variant_id; site 0x05f9d0 jsr-routed
data   0x426d10 +0x140  site_thunk select_pal_variant_id data block <- vsav2 0x3c2a3c
code   0x0df540 +0x38  site_thunk select_pal_variant_id; site 0x05f146 jsr-routed
code   0x08459c +0x2  code_word select_companion_entry_0f (slot entry -> 0046)
code   0x0282fa +0x2  code_word obj_bank_word_slot (slot entry -> 1000)
code   0x05f24c +0x2  code_word win_pos_x_slot (slot entry -> 00f0)
code   0x05f24e +0x2  code_word win_pos_y_slot (slot entry -> 0098)
# M5: sfx helper 0x5122 UN-STUBBED -> vsavj 0x4ce2 (record array don_sfx_records is placed)
# image: extend to 0x600000 (4 x 0x80000 member(s): vsw.41, vsw.42, vsw.43, vsw.44)
