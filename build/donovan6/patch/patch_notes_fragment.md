# donovan-m2 stage 6 — generated op notes

# stage 1: Jedah hitbox block 0x0B0C2E+0x0 (base 0xb0d2e comp 0xb0c2e)
# table_fix: region x026142 len 0x1400 -> 0x1440 (ported per-char OBJ bank table -> vanilla vsavj values (0x282D4))
# layout group at 0xbf6a0+0xdcec: code@0xbf6a0, x05c800@0xc2a10, x065952@0xcbb62, x065c22@0xcbe32, x065e5a@0xcc06a, x066ec4@0xcd0d4; 0x29ec gap bytes recycled
# layout group at 0xcd390+0x2de0: x026142@0xcd390, x028122@0xcf370; 0x358c gap bytes recycled
# anim: gfx_remap +0x2750 on 13418 band tile words, 223 exception words, 1123 effect words (237 blocks pooled; 775 band srcs skipped; 358 protected) in 1160 records
data_file 0x0d3070 +0x20f00  donovan anim (from vsav2 0x27F548)
data_file 0x0c9410 +0xf10  donovan aux0_0 (from vsav2 0x334B80)
data_file 0x0ca320 +0x190  donovan aux0_1 (from vsav2 0x337460)
data_file 0x0ca4b0 +0x1a0  donovan aux0_2 (from vsav2 0x33CCF0)
data_file 0x0ca650 +0x190  donovan aux0_3 (from vsav2 0x34CB60)
data_file 0x3ec720 +0xe070  donovan aux0_4 (from vsav2 0x352120)
code   0x0cb7e0 slot-clearing alloc wrapper for 0x15702 -> 0x16fba (0x80 cleared, +8 preserved)
code   0x0cb810 farm-port stub for 0x29184 (param at 0x0c2a00, common 0x29f4a)
code   0x0cb830 farm-port stub for 0x2918c (param at 0x0cb820, common 0x29f4a)
code   0x0cb840 slot-clearing alloc wrapper for 0x1572e -> 0x16fe6 (0x80 cleared, +8 preserved)
code   0x0cb870 ILLEGAL  TRIPWIRE for unresolved 0x4223c
# code+0x1b08: unresolved 0x4223c -> tripwire 0xcb870
code   0x0cb880 ILLEGAL  TRIPWIRE for unresolved 0x42cee
# code+0x21e0: unresolved 0x42cee -> tripwire 0xcb880
code   0x0cb890 ILLEGAL  TRIPWIRE for unresolved 0x448d4
# code+0x3092: unresolved 0x448d4 -> tripwire 0xcb890
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
# hitbox+0x1349: region_fix 4e -> 06 (sworded deity hit 7/7: type 0x4E -> 0x06 (vs2 dispatch alias — class-8 native electric))
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
code   0x0cb8a0 ILLEGAL  TRIPWIRE for unresolved 0x12f484
# x05c800+0x152a: unresolved 0x12f484 -> tripwire 0xcb8a0
# x05c800+0x16a4: unresolved 0x12f484 -> tripwire 0xcb8a0
code   0x0cb8b0 ILLEGAL  TRIPWIRE for unresolved 0x167bf4
# x05c800+0x2622: unresolved 0x167bf4 -> tripwire 0xcb8b0
# x05c800+0x2a20: unresolved 0x167bf4 -> tripwire 0xcb8b0
code   0x0cb8c0 ILLEGAL  TRIPWIRE for unresolved 0x17f176
# x05c800+0x2ae4: unresolved 0x17f176 -> tripwire 0xcb8c0
# x05c800+0x3034: unresolved 0x17f176 -> tripwire 0xcb8c0
code   0x0cb8d0 ILLEGAL  TRIPWIRE for unresolved 0x181592
# x05c800+0x3072: unresolved 0x181592 -> tripwire 0xcb8d0
# x05c800+0x738: port_patch 3d7c60000018 -> 3d7c40000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 (Jedah band))
# x05c800+0x58d4: port_patch 397c60000018 -> 397c40000018 (OBJ bank setter (a4 form): vs2 bank 3 -> vsav bank 2)
# x05c800+0x5994: port_patch 397c60000018 -> 397c40000018 (OBJ bank setter (a4 form): vs2 bank 3 -> vsav bank 2)
code_file 0x0c2a10 +0x6a00  donovan x05c800 (from vsav2 0x05C800)
code_file 0x0cbb62 +0x2d0  donovan x065952 (from vsav2 0x065952)
code_file 0x0cbe32 +0x100  donovan x065c22 (from vsav2 0x065C22)
code   0x0cb8e0 +0x40  patched clone of 0x5459a for vs2 0x5c77e (unmasked set-anim entry; false byte-matc)
code_file 0x0cc06a +0x106a  donovan x065e5a (from vsav2 0x065E5A)
code_file 0x0cd0d4 +0x2b8  donovan x066ec4 (from vsav2 0x066EC4)
code_file 0x0c28a0 +0x154  donovan x06717c (from vsav2 0x06717C)
code   0x0cb920 ILLEGAL  TRIPWIRE for unresolved 0x24edd4
# x088512+0x1362: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x13a0: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x13e4: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x1428: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x1464: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x14a2: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x150a: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x154e: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x1590: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x15f0: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x1670: unresolved 0x24edd4 -> tripwire 0xcb920
code   0x0cb930 ILLEGAL  TRIPWIRE for unresolved 0x24a3ce
# x088512+0x16d8: unresolved 0x24a3ce -> tripwire 0xcb930
# x088512+0x1732: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x1796: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x17fa: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x18ee: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x191c: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x194a: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x1994: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x1cd2: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x1d1a: unresolved 0x24edd4 -> tripwire 0xcb920
code   0x0cb940 ILLEGAL  TRIPWIRE for unresolved 0x36784a
# x088512+0x1dee: unresolved 0x36784a -> tripwire 0xcb940
code   0x0cb950 ILLEGAL  TRIPWIRE for unresolved 0x25111e
# x088512+0x2156: unresolved 0x25111e -> tripwire 0xcb950
# x088512+0x21d2: unresolved 0x25111e -> tripwire 0xcb950
# x088512+0x26e2: unresolved 0x25111e -> tripwire 0xcb950
code   0x0cb960 ILLEGAL  TRIPWIRE for unresolved 0x2695d0
# x088512+0x2894: unresolved 0x2695d0 -> tripwire 0xcb960
# x088512+0x28ce: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x290c: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x294a: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x2986: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x29c4: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x2a2c: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x2a6a: unresolved 0x24edd4 -> tripwire 0xcb920
# x088512+0x209c: char-id imm 0x13 -> 0xf
code   0x0cead0 ILLEGAL  shared pcrel TRIPWIRE for x088512
# x088512: 9 pcrel escape entries rewritten (tripwire at 0xcead0)
# x088512+0x2be6: port_patch 000e -> 000c (companion queue class 7 (vs2-only) -> vsavj class 6)
# x088512+0x22c: port_patch 3d7c60000018 -> 3d7c40000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2)
# x088512+0x1814: port_patch 3d7c60000018 -> 3d7c40000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2)
# x088512+0x2bee: port_patch 3d7c60000018 -> 3d7c40000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2)
code_file 0x0d0170 +0x2f00  donovan x088512 (from vsav2 0x088512)
code   0x0ceae0 ILLEGAL  shared pcrel TRIPWIRE for x0905ae
# x0905ae: 2 pcrel escape entries rewritten (tripwire at 0xceae0)
code_file 0x0ce7d0 +0x300  donovan x0905ae (from vsav2 0x0905AE)
code   0x0cb970 ILLEGAL  TRIPWIRE for unresolved 0x2c3136
# x2b7ef4+0xb0c9: unresolved 0x2c3136 -> tripwire 0xcb970
code   0x0cb980 ILLEGAL  TRIPWIRE for unresolved 0x2c3170
# x2b7ef4+0xb0d1: unresolved 0x2c3170 -> tripwire 0xcb980
code   0x0cb990 ILLEGAL  TRIPWIRE for unresolved 0x2c31aa
# x2b7ef4+0xb0d9: unresolved 0x2c31aa -> tripwire 0xcb990
code   0x0cb9a0 ILLEGAL  TRIPWIRE for unresolved 0x2c31e4
# x2b7ef4+0xb0fd: unresolved 0x2c31e4 -> tripwire 0xcb9a0
code   0x0cb9b0 ILLEGAL  TRIPWIRE for unresolved 0x2c3236
# x2b7ef4+0xb105: unresolved 0x2c3236 -> tripwire 0xcb9b0
code   0x0cb9c0 ILLEGAL  TRIPWIRE for unresolved 0x2c325c
# x2b7ef4+0xb10d: unresolved 0x2c325c -> tripwire 0xcb9c0
code   0x0cb9d0 ILLEGAL  TRIPWIRE for unresolved 0x2c3272
# x2b7ef4+0xb115: unresolved 0x2c3272 -> tripwire 0xcb9d0
code   0x0cb9e0 ILLEGAL  TRIPWIRE for unresolved 0x2c3280
# x2b7ef4+0xb11d: unresolved 0x2c3280 -> tripwire 0xcb9e0
code   0x0cb9f0 ILLEGAL  TRIPWIRE for unresolved 0x2c3296
# x2b7ef4+0xb125: unresolved 0x2c3296 -> tripwire 0xcb9f0
code   0x0cba00 ILLEGAL  TRIPWIRE for unresolved 0x2c32a4
# x2b7ef4+0xb12d: unresolved 0x2c32a4 -> tripwire 0xcba00
code   0x0cba10 ILLEGAL  TRIPWIRE for unresolved 0x2c32b2
# x2b7ef4+0xb135: unresolved 0x2c32b2 -> tripwire 0xcba10
# x2b7ef4: effect_tail — 128 bank-1 words, 308 bank-2 words (tail placements), 114 coord lists matched, 617 ported (11336B fragment)
data_file 0x0f3f70 +0xb20c  donovan x2b7ef4 (from vsav2 0x2B7EF4)
data     0x0ceaf0 +0x500  sprite palette block (vsav2 0x39CB9C); poke32 0x38c1d4 (table 0x38c198 row 0xf)
data     0x0ff180 +0xdc0  effect palette block (vsav2 0x3ADFDC); poke32 0x38c254 (table 0x38c218 row 0xf)
data     0x0ff180 +0xdc0  effect palette block (vsav2 0x3ADFDC); poke32 0x38c294 (table 0x38c258 row 0xf)
poke32 0x0bceb6 <- 0x000d3070  anim_index_a[0xf] donovan anim
poke32 0x0bcef6 <- 0x000d3070  anim_index_a[0x1f] variant mirror
poke32 0x0bcf36 <- 0x000d51be  anim_index_a2[0xf] donovan anim
poke32 0x0bcf76 <- 0x000d51be  anim_index_a2[0x1f] variant mirror
poke32 0x0bcfb6 <- 0x000dabc4  anim_index_b[0xf] donovan anim
poke32 0x0bcff6 <- 0x000dabc4  anim_index_b[0x1f] variant mirror
poke32 0x0bd036 <- 0x000dacba  anim_index_c[0xf] donovan anim
poke32 0x0bd076 <- 0x000dacba  anim_index_c[0x1f] variant mirror
poke32 0x0bd0b6 <- 0x000dda1e  anim_index_proj[0xf] donovan anim
poke32 0x0bd0f6 <- 0x000dda1e  anim_index_proj[0x1f] variant mirror
# param32_a: velocity pair NOT ported (14w-b crash guard; Jedah speeds retained)
poke32 0x0bd9b6 <- 0x003fa9d0  hitbox_base[0xf] donovan hitbox
poke32 0x0bd9f6 <- 0x003fa9d0  hitbox_base[0x1f] variant mirror
poke32 0x0bda36 <- 0x003fa790  hitbox_comp[0xf] donovan hitbox
poke32 0x0bda76 <- 0x003fa790  hitbox_comp[0x1f] variant mirror
poke32 0x0bdab6 <- 0x000ca7e0  proj_hitbox_base[0xf] donovan hitbox_proj
poke32 0x0bdaf6 <- 0x000ca7e0  proj_hitbox_base[0x1f] variant mirror
poke32 0x0bdb36 <- 0x000cab3a  proj_hitbox_comp[0xf] donovan hitbox_proj
poke32 0x0bdb76 <- 0x000cab3a  proj_hitbox_comp[0x1f] variant mirror
data   0x0bdbf2 +0x8  rec8_a[0xf] value
data   0x0bdc72 +0x8  rec8_a[0x1f] mirror
data   0x0be198 +0x2  word132[0xf] value
data   0x0be1b8 +0x2  word132[0x1f] mirror
data   0x0be1d8 +0x2  word_pos_a[0xf] value
data   0x0be1f8 +0x2  word_pos_a[0x1f] mirror
data   0x0be218 +0x2  word_pos_b[0xf] value
data   0x0be238 +0x2  word_pos_b[0x1f] mirror
# param32_b: velocity pair NOT ported (14w-b crash guard; Jedah speeds retained)
data   0x0be472 +0x8  rec8_b[0xf] value
data   0x0be4f2 +0x8  rec8_b[0x1f] mirror
data   0x0be818 +0x2  word_y_off[0xf] value
data   0x0be838 +0x2  word_y_off[0x1f] mirror
data   0x0be858 +0x2  word_range[0xf] value
data   0x0be878 +0x2  word_range[0x1f] mirror
data   0x0be888 +0x2  byte15b[0xf] value
data   0x0be898 +0x2  byte15b[0x1f] mirror
data   0x0bea5c +0x1e  byte2d_a[0xf] value
data   0x0bec3c +0x1e  byte2d_a[0x1f] mirror
data   0x0bee1c +0x1e  byte2d_b[0xf] value
data   0x0beffc +0x1e  byte2d_b[0x1f] mirror
poke32 0x0bf2d6 <- 0x000bfcec  tail_code_ptr[0xf] donovan code
poke32 0x0bf316 <- 0x000bfcec  tail_code_ptr[0x1f] variant mirror
poke32 0x0bf456 <- 0x003fcbf2  tail_data_ptr[0xf] donovan hitbox
poke32 0x0bf496 <- 0x003fcbf2  tail_data_ptr[0x1f] variant mirror
code   0x0cba20 ILLEGAL  TRIPWIRE for unresolved 0x672d0
# obj_hook@0x54470 type 64: unresolved 0x672d0 -> tripwire 0xcba20
code   0x0cba30 ILLEGAL  TRIPWIRE for unresolved 0x67550
# obj_hook@0x54470 type 65: unresolved 0x67550 -> tripwire 0xcba30
code   0x0cba40 ILLEGAL  TRIPWIRE for unresolved 0x67846
# obj_hook@0x54470 type 66: unresolved 0x67846 -> tripwire 0xcba40
code   0x0cba50 ILLEGAL  TRIPWIRE for unresolved 0x67a00
# obj_hook@0x54470 type 67: unresolved 0x67a00 -> tripwire 0xcba50
code   0x0cba60 ILLEGAL  TRIPWIRE for unresolved 0x6800c
# obj_hook@0x54470 type 68: unresolved 0x6800c -> tripwire 0xcba60
code   0x0cba70 ILLEGAL  TRIPWIRE for unresolved 0x68458
# obj_hook@0x54470 type 69: unresolved 0x68458 -> tripwire 0xcba70
code   0x0cba80 ILLEGAL  TRIPWIRE for unresolved 0x68768
# obj_hook@0x54470 type 70: unresolved 0x68768 -> tripwire 0xcba80
code   0x0cba90 ILLEGAL  TRIPWIRE for unresolved 0x689cc
# obj_hook@0x54470 type 71: unresolved 0x689cc -> tripwire 0xcba90
code   0x0cbaa0 ILLEGAL  TRIPWIRE for unresolved 0x68c78
# obj_hook@0x54470 type 72: unresolved 0x68c78 -> tripwire 0xcbaa0
code   0x0cbab0 ILLEGAL  TRIPWIRE for unresolved 0x69046
# obj_hook@0x54470 type 73: unresolved 0x69046 -> tripwire 0xcbab0
code   0x0cbac0 ILLEGAL  TRIPWIRE for unresolved 0x692f6
# obj_hook@0x54470 type 74: unresolved 0x692f6 -> tripwire 0xcbac0
code   0x0cbad0 ILLEGAL  TRIPWIRE for unresolved 0x6965e
# obj_hook@0x54470 type 75: unresolved 0x6965e -> tripwire 0xcbad0
data   0x0ceff0 +0x130  proj_hook extended type table (59 vanilla + 17 ported, 5 placed)
code   0x0cbae0 obj_hook thunk (ghost-clean: returns to vanilla jsr)
code   0x054470 ENGINE HOOK: dispatch -> jmp thunk; vanilla jsr (A0) at 0x54476 untouched (vanilla types identical via table copy)
code   0x0cbb00 ILLEGAL  TRIPWIRE for unresolved 0x6a70c
# obj_hook@0x5e542 type 121: unresolved 0x6a70c -> tripwire 0xcbb00
# obj_hook@0x5e542 type 122: unresolved 0x6a70c -> tripwire 0xcbb00
# obj_hook@0x5e542 type 123: unresolved 0x6a70c -> tripwire 0xcbb00
data   0x0cf120 +0x1f0  proj_hook extended type table (114 vanilla + 10 ported, 7 placed)
code   0x0cbb10 obj_hook thunk (ghost-clean: returns to vanilla jsr)
code   0x05e542 ENGINE HOOK: dispatch -> jmp thunk; vanilla jsr (A0) at 0x5e548 untouched (vanilla types identical via table copy)
data   0x3ff9b0 +0x180  state_hook palette-seq records (ids 0x2cd-0x2d8)
code   0x0cbb30 state_hook private seq entry (records base 0x3ff9b0 - 0x2cd*32 -> engine 0x2ad9a)
code   0x02a7c8 ENGINE HOOK: +0x14e state dispatch -> thunk 0x0cbf70 (vanilla ids ghost-clean via jmp-back; ids 0xb2-0xc8 -> 12 synthesized stubs at 0x3ffb30, ext table 0x0cbf40)
code   0x018458 ENGINE HOOK: hit-reaction dispatch -> thunk 0x0cbfe0 (vanilla ids jmp back to untouched 0x18460; ids 0xa0-0xa6 -> 4 verbatim vs2 cases at 0x0cbfb0)
code   0x0cc020 init shim (pool latch A5+0x7966, seeder 0x16c64; flavor (A6+0x3c2)<-0x01, Start-held [0xff8060 bit=player] -> 0x00) -> handler 0x0c1030
poke32 0x0bd136 <- 0x000cc020  dispatch_00[0xf] donovan handler via seed shim
poke32 0x0bd176 <- 0x000cc020  dispatch_00[0x1f] variant mirror
poke32 0x0bd1b6 <- 0x000bf6aa  dispatch_01[0xf] donovan handler
poke32 0x0bd1f6 <- 0x000bf6aa  dispatch_01[0x1f] variant mirror
poke32 0x0bd236 <- 0x000bff64  dispatch_02[0xf] donovan handler
poke32 0x0bd276 <- 0x000bff64  dispatch_02[0x1f] variant mirror
poke32 0x0bd2b6 <- 0x000bff64  dispatch_03[0xf] donovan handler
poke32 0x0bd2f6 <- 0x000bff64  dispatch_03[0x1f] variant mirror
poke32 0x0bd336 <- 0x000bff64  dispatch_04[0xf] donovan handler
poke32 0x0bd376 <- 0x000bff64  dispatch_04[0x1f] variant mirror
poke32 0x0bd3b6 <- 0x000c0a12  dispatch_05[0xf] donovan handler
poke32 0x0bd3f6 <- 0x000c0a12  dispatch_05[0x1f] variant mirror
poke32 0x0bd436 <- 0x000bfa9c  dispatch_06[0xf] donovan handler
poke32 0x0bd476 <- 0x000bfa9c  dispatch_06[0x1f] variant mirror
poke32 0x0bd4b6 <- 0x000c0cb0  dispatch_07[0xf] donovan handler
poke32 0x0bd4f6 <- 0x000c0cb0  dispatch_07[0x1f] variant mirror
poke32 0x0bd536 <- 0x000bfb30  dispatch_08[0xf] donovan handler
poke32 0x0bd576 <- 0x000bfb30  dispatch_08[0x1f] variant mirror
poke32 0x0bd5b6 <- 0x000bfc32  dispatch_09[0xf] donovan handler
poke32 0x0bd5f6 <- 0x000bfc32  dispatch_09[0x1f] variant mirror
poke32 0x0bd636 <- 0x000bf9d2  dispatch_10[0xf] donovan handler
poke32 0x0bd676 <- 0x000bf9d2  dispatch_10[0x1f] variant mirror
poke32 0x0bd6b6 <- 0x000c0dfa  dispatch_11[0xf] donovan handler
poke32 0x0bd6f6 <- 0x000c0dfa  dispatch_11[0x1f] variant mirror
poke32 0x0bd736 <- 0x000c0f9c  dispatch_12[0xf] donovan handler
poke32 0x0bd776 <- 0x000c0f9c  dispatch_12[0x1f] variant mirror
poke32 0x0bd7b6 <- 0x000c0fe6  dispatch_13[0xf] donovan handler
poke32 0x0bd7f6 <- 0x000c0fe6  dispatch_13[0x1f] variant mirror
poke32 0x0bd836 <- 0x000c0d74  dispatch_14[0xf] donovan handler
poke32 0x0bd876 <- 0x000c0d74  dispatch_14[0x1f] variant mirror
poke32 0x0bf256 <- 0x000bfb54  dispatch_15[0xf] donovan handler
poke32 0x0bf296 <- 0x000bfb54  dispatch_15[0x1f] variant mirror
poke32 0x0bf356 <- 0x000c109c  dispatch_16[0xf] donovan handler
poke32 0x0bf396 <- 0x000c109c  dispatch_16[0x1f] variant mirror
poke32 0x0bf3d6 <- 0x000c10d8  dispatch_17[0xf] donovan handler
poke32 0x0bf416 <- 0x000c10d8  dispatch_17[0x1f] variant mirror
poke32 0x0bf4d6 <- 0x000c1124  dispatch_18[0xf] donovan handler
poke32 0x0bf516 <- 0x000c1124  dispatch_18[0x1f] variant mirror
poke32 0x0bf656 <- 0x000c1106  dispatch_19[0xf] donovan handler
poke32 0x0bf696 <- 0x000c1106  dispatch_19[0x1f] variant mirror
data   0x0b19f8 +0xe50  data_port throw_victim_keyframes <- vsav2 0x0ca1ca (0 fixes)
data   0x39fbe0 +0x20  data_port weapon_accent_t0 <- vsav2 0x39cbdc (0 fixes)
data   0x39fc00 +0x20  data_port weapon_accent_t1 <- vsav2 0x39cbdc (0 fixes)
data   0x39fc20 +0x20  data_port weapon_accent_rowd_slot <- vsav2 0x39cbfc (0 fixes)
data   0x028d50 +0x4  data_port hit_class_props_ext_hi <- vsav2 0x028028 (0 fixes)
data   0x028d4e +0x2  data_port hit_class_props_ext_lo <- vsav2 0x028026 (0 fixes)
code   0x3ffcb0 +0x62  site_thunk fixture_row0f_override_bank0; site 0x01c586 jsr-routed
code   0x3ffd20 +0x62  site_thunk fixture_row0f_override_bank1; site 0x01c59a jsr-routed
code   0x0cf310 +0x18  site_thunk select_companion_tbl_a; site 0x0845ec jsr-routed
code   0x0cf330 +0x18  site_thunk select_companion_tbl_b; site 0x0845f8 jsr-routed
code   0x0fff40 +0x22  site_thunk select_companion_resolve_s1; site 0x084602 jsr-routed
code   0x0fff70 +0x22  site_thunk select_companion_resolve_s2; site 0x084624 jsr-routed
code   0x0cf350 +0x1c  site_thunk accent_color_aware_0; site 0x02ad82 jsr-routed
code   0x0fffa0 +0x1c  site_thunk accent_color_aware_1; site 0x02ad94 jsr-routed
code   0x0fffc0 +0x1c  site_thunk accent_color_aware_2; site 0x02b342 jsr-routed
code   0x0fffe0 +0x1c  site_thunk accent_color_aware_3; site 0x02b7e8 jsr-routed
code   0x3ffd90 +0x2a  site_thunk ls_freeze_vs2_victim; site 0x023ad8 jsr-routed
code   0x3ffdc0 +0x24  site_thunk ls_freeze_vs2_attacker; site 0x023ade jsr-routed
code   0x3ffdf0 +0x16  site_thunk es_type51_dispatch; site 0x0185ca jsr-routed
code   0x084594 +0x2  code_word select_companion_entry_0f (0040 -> 0046)
