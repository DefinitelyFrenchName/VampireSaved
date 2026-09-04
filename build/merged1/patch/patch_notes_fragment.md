# donovan-m2 stage 6 — generated op notes

# stage 1: Jedah hitbox block 0x09755E+0x0 (base 0x9769e comp 0x9755e)
# table_fix: region x026142 len 0x1400 -> 0x1440 (merged vanilla bank table; tenant rows written per tenant)
# layout group at 0xbf6a0+0xdcec: code@0xbf6a0, x05c800@0xc2a10, x065952@0xcbb62, x065c22@0xcbe32, x065e5a@0xcc06a, x066ec4@0xcd0d4; 0x29cc gap bytes recycled
# layout group at 0xcd390+0x2de0: x026142@0xcd390, x028122@0xcf370; 0x350c gap bytes recycled
# anim: gfx_remap +0x2750 on 13418 band tile words, 223 exception words, 1123 effect words (237 blocks pooled; 775 band srcs skipped; 358 protected) in 1160 records
data_file 0x0d3070 +0x20f00  donovan anim (from vsav2 0x27F548)
data_file 0x0c9430 +0xf10  donovan aux0_0 (from vsav2 0x334B80)
data_file 0x0ca340 +0x190  donovan aux0_1 (from vsav2 0x337460)
data_file 0x0ca4d0 +0x1a0  donovan aux0_2 (from vsav2 0x33CCF0)
data_file 0x0ca670 +0x190  donovan aux0_3 (from vsav2 0x34CB60)
data_file 0x3ec720 +0xe070  donovan aux0_4 (from vsav2 0x352120)
code   0x0cb800 slot-clearing alloc wrapper for 0x15702 -> 0x16fba (0x80 cleared, +8 preserved)
code   0x0c2a00 farm-port stub for 0x2916c (param at 0x0cb830, common 0x29f4a)
code   0x0cb860 farm-port stub for 0x2915c (param at 0x0cb850, common 0x29f4a)
code   0x0cb880 farm-port stub for 0x29164 (param at 0x0cb870, common 0x29f4a)
code   0x0cb8a0 farm-port stub for 0x29184 (param at 0x0cb890, common 0x29f4a)
code   0x0cb8c0 farm-port stub for 0x2918c (param at 0x0cb8b0, common 0x29f4a)
code   0x0cb8d0 slot-clearing alloc wrapper for 0x1572e -> 0x16fe6 (0x80 cleared, +8 preserved)
code   0x0cb900 ILLEGAL  TRIPWIRE for unresolved 0x4223c
# code+0x1b08: unresolved 0x4223c -> tripwire 0xcb900
code   0x0cb910 ILLEGAL  TRIPWIRE for unresolved 0x42cee
# code+0x21e0: unresolved 0x42cee -> tripwire 0xcb910
code   0x0cb920 ILLEGAL  TRIPWIRE for unresolved 0x448d4
# code+0x3092: unresolved 0x448d4 -> tripwire 0xcb920
code   0x0cb930 owner-tag thunk (donovan id 0x13 -> (+0x7f,A4), then stamp_b_d16 197c003e0002, rts)
# code+0x98a: owner_tag stamp_b_d16 type 62 -> jsr 0xcb930 (donovan id 0x13)
code   0x0cb940 owner-tag thunk (donovan id 0x13 -> (+0x7f,A4), then stamp_b_d16 197c003f0002, rts)
# code+0xb10: owner_tag stamp_b_d16 type 63 -> jsr 0xcb940 (donovan id 0x13)
code   0x0cb950 owner-tag thunk (donovan id 0x13 -> (+0x7f,A4), then stamp_b_d16 197c004b0002, rts)
# code+0xb1c: owner_tag stamp_b_d16 type 75 -> jsr 0xcb950 (donovan id 0x13)
code   0x0cb960 owner-tag thunk (donovan id 0x13 -> (+0x7f,A4), then stamp_b_d16 197c003d0002, rts)
# code+0x19c4: owner_tag stamp_b_d16 type 61 -> jsr 0xcb960 (donovan id 0x13)
code   0x0cb970 owner-tag thunk (donovan id 0x13 -> (+0x7f,A4), then stamp_b_d16 197c00490002, rts)
# code+0x25ea: owner_tag stamp_b_d16 type 73 -> jsr 0xcb970 (donovan id 0x13)
code   0x0cb980 owner-tag thunk (donovan id 0x13 -> (+0x7f,A4), then stamp_l_ind 28bc01014200, rts)
# code+0x2cd8: owner_tag stamp_l_ind type 66 -> jsr 0xcb980 (donovan id 0x13)
code   0x0cb990 owner-tag thunk (donovan id 0x13 -> (+0x7f,A4), then stamp_l_ind 28bc01004202, rts)
# code+0x2da2: owner_tag stamp_l_ind type 66 -> jsr 0xcb990 (donovan id 0x13)
code_file 0x0bf6a0 +0x3200  donovan code (from vsav2 0x059490)
# hitbox+0x10e9: region_fix 51 -> 44 (deity node next-state vs2 0x51 -> 0x44 (the 14z-110b five-consumer equivalence; 14z-35 tried 0x4E and 14z-43 retired it — 0x44 preserves property 0x19 AND the 0x2384E handler family))
# hitbox+0x1109: region_fix 51 -> 44 (deity node next-state vs2 0x51 -> 0x44 (the 14z-110b five-consumer equivalence; 14z-35 tried 0x4E and 14z-43 retired it — 0x44 preserves property 0x19 AND the 0x2384E handler family))
# hitbox+0x1129: region_fix 51 -> 44 (deity node next-state vs2 0x51 -> 0x44 (the 14z-110b five-consumer equivalence; 14z-35 tried 0x4E and 14z-43 retired it — 0x44 preserves property 0x19 AND the 0x2384E handler family))
# hitbox+0x1149: region_fix 51 -> 44 (deity node next-state vs2 0x51 -> 0x44 (the 14z-110b five-consumer equivalence; 14z-35 tried 0x4E and 14z-43 retired it — 0x44 preserves property 0x19 AND the 0x2384E handler family))
# hitbox+0x1169: region_fix 51 -> 44 (deity node next-state vs2 0x51 -> 0x44 (the 14z-110b five-consumer equivalence; 14z-35 tried 0x4E and 14z-43 retired it — 0x44 preserves property 0x19 AND the 0x2384E handler family))
# hitbox+0x1189: region_fix 51 -> 44 (deity node next-state vs2 0x51 -> 0x44 (the 14z-110b five-consumer equivalence; 14z-35 tried 0x4E and 14z-43 retired it — 0x44 preserves property 0x19 AND the 0x2384E handler family))
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
data_file 0x0ca800 +0x1000  donovan hitbox_proj (from vsav2 0x0D0CA8)
# x026142+0x1414: bank table row 0x13 <- 0x1000 (bank 4, WIDE encoding; vanilla row was 0x2000) — tenant-driven
# x026142+0x140e: bank table row 0x10 <- 0x1000 (bank 4, WIDE encoding; vanilla row was 0x6000) — tenant-driven
# x026142+0x1410: bank table row 0x11 <- 0x1000 (bank 4, WIDE encoding; vanilla row was 0x6000) — tenant-driven
# x026142+0x13ee: table_fix 48 bytes (merged vanilla bank table; tenant rows written per tenant)
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
# pcrel_escape_fix x026142: 9 escapes -> 6 trampolines (0 tripwired), pad 0x1440..0x14a0
code_file 0x0cd390 +0x14a0  donovan x026142 (from vsav2 0x026142)
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
code   0x0cb9a0 ILLEGAL  TRIPWIRE for unresolved 0x12f484
# x05c800+0x152a: unresolved 0x12f484 -> tripwire 0xcb9a0
# x05c800+0x16a4: unresolved 0x12f484 -> tripwire 0xcb9a0
code   0x0cb9b0 ILLEGAL  TRIPWIRE for unresolved 0x167bf4
# x05c800+0x2622: unresolved 0x167bf4 -> tripwire 0xcb9b0
# x05c800+0x2a20: unresolved 0x167bf4 -> tripwire 0xcb9b0
code   0x0cb9c0 ILLEGAL  TRIPWIRE for unresolved 0x17f176
# x05c800+0x2ae4: unresolved 0x17f176 -> tripwire 0xcb9c0
# x05c800+0x3034: unresolved 0x17f176 -> tripwire 0xcb9c0
code   0x0cb9d0 ILLEGAL  TRIPWIRE for unresolved 0x181592
# x05c800+0x3072: unresolved 0x181592 -> tripwire 0xcb9d0
# x05c800+0x738: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 (Jedah band) / WIDE bank 4)
# x05c800+0x58d4: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (a4 form): vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x05c800+0x5994: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (a4 form): vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
code   0x0cb9e0 owner-tag thunk (donovan id 0x13 -> (+0x7f,A4), then stamp_l_ind 28bc01003b22, rts)
# x05c800+0x83a: owner_tag stamp_l_ind type 59 -> jsr 0xcb9e0 (donovan id 0x13)
# pcrel_escape_fix x05c800: 2 escapes -> 1 trampolines (0 tripwired), pad 0x6a00..0x6a20
code_file 0x0c2a10 +0x6a20  donovan x05c800 (from vsav2 0x05C800)
code_file 0x0cbb62 +0x2d0  donovan x065952 (from vsav2 0x065952)
code_file 0x0cbe32 +0x100  donovan x065c22 (from vsav2 0x065C22)
code   0x0cb9f0 +0x40  patched clone of 0x5459a for vs2 0x5c77e (unmasked set-anim entry; false byte-matc)
code   0x0cba30 sound stub for 0x5086 (vsavj sfx id 0x75)
code_file 0x0cc06a +0x106a  donovan x065e5a (from vsav2 0x065E5A)
code_file 0x0cd0d4 +0x2b8  donovan x066ec4 (from vsav2 0x066EC4)
code_file 0x0c28a0 +0x154  donovan x06717c (from vsav2 0x06717C)
code   0x0cba50 ILLEGAL  TRIPWIRE for unresolved 0x24edd4
# x088512+0x1362: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x13a0: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x13e4: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x1428: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x1464: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x14a2: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x150a: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x154e: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x1590: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x15f0: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x1670: unresolved 0x24edd4 -> tripwire 0xcba50
code   0x0cba60 ILLEGAL  TRIPWIRE for unresolved 0x24a3ce
# x088512+0x16d8: unresolved 0x24a3ce -> tripwire 0xcba60
# x088512+0x1732: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x1796: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x17fa: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x18ee: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x191c: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x194a: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x1994: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x1cd2: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x1d1a: unresolved 0x24edd4 -> tripwire 0xcba50
code   0x0cba70 ILLEGAL  TRIPWIRE for unresolved 0x36784a
# x088512+0x1dee: unresolved 0x36784a -> tripwire 0xcba70
code   0x0cba80 sound stub for 0x50ee (vsavj sfx id 0x7e)
code   0x0cbaa0 sound stub for 0x50a0 (vsavj sfx id 0x7b)
code   0x0cbac0 sound stub for 0x50d4 (vsavj sfx id 0x7d)
code   0x0cbae0 sound stub for 0x50ba (vsavj sfx id 0x7c)
code   0x0cbb00 ILLEGAL  TRIPWIRE for unresolved 0x25111e
# x088512+0x2156: unresolved 0x25111e -> tripwire 0xcbb00
# x088512+0x21d2: unresolved 0x25111e -> tripwire 0xcbb00
# x088512+0x26e2: unresolved 0x25111e -> tripwire 0xcbb00
code   0x0cbb10 sound stub for 0x4e2a (vsavj sfx id 0x8f)
code   0x0cbb30 sound stub for 0x4df6 (vsavj sfx id 0x86)
code   0x0cbb50 ILLEGAL  TRIPWIRE for unresolved 0x2695d0
# x088512+0x2894: unresolved 0x2695d0 -> tripwire 0xcbb50
# x088512+0x28ce: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x290c: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x294a: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x2986: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x29c4: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x2a2c: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x2a6a: unresolved 0x24edd4 -> tripwire 0xcba50
# x088512+0x209c: char-id imm 0x13 -> 0x13
code   0x0ceb30 ILLEGAL  shared pcrel TRIPWIRE for x088512
# x088512: 9 pcrel escape entries rewritten (tripwire at 0xceb30)
# x088512+0x2be6: port_patch 000e -> 000c (companion queue class 7 (vs2-only) -> vsavj class 6)
# x088512+0x22c: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x088512+0x1814: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x088512+0x2bee: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
code   0x0cbf40 owner-tag thunk (donovan id 0x13 -> (+0x7f,A4), then stamp_l_ind 28bc01014102, rts)
# x088512+0x2ebc: owner_tag stamp_l_ind type 65 -> jsr 0xcbf40 (donovan id 0x13)
code_file 0x0d0170 +0x2f00  donovan x088512 (from vsav2 0x088512)
code   0x0ceb40 ILLEGAL  shared pcrel TRIPWIRE for x0905ae
# x0905ae: 2 pcrel escape entries rewritten (tripwire at 0xceb40)
code_file 0x0ce830 +0x300  donovan x0905ae (from vsav2 0x0905AE)
data_file 0x400010 +0x10ce  donovan x101aca (from vsav2 0x101ACA)
code   0x0cbb60 ILLEGAL  TRIPWIRE for unresolved 0x2c3136
# x2b7ef4+0xb0c9: unresolved 0x2c3136 -> tripwire 0xcbb60
code   0x0cbf50 ILLEGAL  TRIPWIRE for unresolved 0x2c3170
# x2b7ef4+0xb0d1: unresolved 0x2c3170 -> tripwire 0xcbf50
code   0x0cbf60 ILLEGAL  TRIPWIRE for unresolved 0x2c31aa
# x2b7ef4+0xb0d9: unresolved 0x2c31aa -> tripwire 0xcbf60
code   0x0cbf70 ILLEGAL  TRIPWIRE for unresolved 0x2c31e4
# x2b7ef4+0xb0fd: unresolved 0x2c31e4 -> tripwire 0xcbf70
code   0x0cbf80 ILLEGAL  TRIPWIRE for unresolved 0x2c3236
# x2b7ef4+0xb105: unresolved 0x2c3236 -> tripwire 0xcbf80
code   0x0cbf90 ILLEGAL  TRIPWIRE for unresolved 0x2c325c
# x2b7ef4+0xb10d: unresolved 0x2c325c -> tripwire 0xcbf90
code   0x0cbfa0 ILLEGAL  TRIPWIRE for unresolved 0x2c3272
# x2b7ef4+0xb115: unresolved 0x2c3272 -> tripwire 0xcbfa0
code   0x0cbfb0 ILLEGAL  TRIPWIRE for unresolved 0x2c3280
# x2b7ef4+0xb11d: unresolved 0x2c3280 -> tripwire 0xcbfb0
code   0x0cbfc0 ILLEGAL  TRIPWIRE for unresolved 0x2c3296
# x2b7ef4+0xb125: unresolved 0x2c3296 -> tripwire 0xcbfc0
code   0x0cbfd0 ILLEGAL  TRIPWIRE for unresolved 0x2c32a4
# x2b7ef4+0xb12d: unresolved 0x2c32a4 -> tripwire 0xcbfd0
code   0x0cbfe0 ILLEGAL  TRIPWIRE for unresolved 0x2c32b2
# x2b7ef4+0xb135: unresolved 0x2c32b2 -> tripwire 0xcbfe0
# x2b7ef4: effect_tail — 128 bank-1 words, 308 bank-2 words (tail placements), 114 coord lists matched, 617 ported (11336B fragment)
data_file 0x0f3f70 +0xb20c  donovan x2b7ef4 (from vsav2 0x2B7EF4)
data     0x0ceb50 +0x500  sprite palette block (vsav2 0x39CB9C); poke32 0x38c1e4 (table 0x38c198 row 0x13)
data     0x0ff180 +0xdc0  effect palette block (vsav2 0x3ADFDC); poke32 0x38c264 (table 0x38c218 row 0x13)
poke32 0x0bcec6 <- 0x000d3070  anim_index_a[0x13] donovan anim
poke32 0x0bcf46 <- 0x000d51be  anim_index_a2[0x13] donovan anim
poke32 0x0bcfc6 <- 0x000dabc4  anim_index_b[0x13] donovan anim
poke32 0x0bd046 <- 0x000dacba  anim_index_c[0x13] donovan anim
poke32 0x0bd0c6 <- 0x000dda1e  anim_index_proj[0x13] donovan anim
data   0x0bd912 +0x8  param32_a[0x13] value
data   0x0bdf0a +0x30  jump_params[0x13] value
poke32 0x0bd9c6 <- 0x003fa9d0  hitbox_base[0x13] donovan hitbox
poke32 0x0bda46 <- 0x003fa790  hitbox_comp[0x13] donovan hitbox
poke32 0x0bdac6 <- 0x000ca800  proj_hitbox_base[0x13] donovan hitbox_proj
poke32 0x0bdb46 <- 0x000cab5a  proj_hitbox_comp[0x13] donovan hitbox_proj
data   0x0bdc12 +0x8  rec8_a[0x13] value
data   0x0be1a0 +0x2  word132[0x13] value
data   0x0be1e0 +0x2  word_pos_a[0x13] value
data   0x0be220 +0x2  word_pos_b[0x13] value
data   0x0be392 +0x8  param32_b[0x13] value
data   0x0be492 +0x8  rec8_b[0x13] value
data   0x0be820 +0x2  word_y_off[0x13] value
data   0x0be860 +0x2  word_range[0x13] value
data   0x0be88c +0x2  byte15b[0x13] value
data   0x0bead4 +0x1e  byte2d_a[0x13] value
data   0x0bee94 +0x1e  byte2d_b[0x13] value
poke32 0x0bf2e6 <- 0x000bfcec  tail_code_ptr[0x13] donovan code
# tail_data_ptr: ptr row owned by sound_table don_sfx_records — generic repoint suppressed (14z-65 sound_table / 14z-130 data_port)
poke32 0x0bf066 <- 0x00400010  ai_script_0[0x13] donovan x101aca
poke32 0x0bf0e6 <- 0x0040010e  ai_script_1[0x13] donovan x101aca
poke32 0x0bf166 <- 0x00400bba  ai_script_2[0x13] donovan x101aca
poke32 0x0bf1e6 <- 0x004010c8  ai_script_3[0x13] donovan x101aca
data   0x0cf050 +0x180  state_hook palette-seq records (ids 0x2cd-0x2d8)
code   0x0cbff0 state_hook private seq entry (records base 0x0cf050 - 0x2cd*32 -> engine 0x2ad9a)
code   0x02a7c8 ENGINE HOOK: +0x14e state dispatch -> thunk 0x0cc030 (vanilla ids ghost-clean via jmp-back; ids 0xb2-0xc8 -> 12 synthesized stubs at 0x0cf1d0, ext table 0x0cc000)
code   0x018458 ENGINE HOOK: hit-reaction dispatch -> thunk 0x0fffa0 (vanilla ids jmp back to untouched 0x18460; ids 0xa0-0xa6 -> 4 verbatim vs2 cases at 0x0fff40; d2 window -> untouched 0x18508, vs2 d2-twin cases at 0x0fff70)
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
poke16 0x01c822 <- 0x2045  aux boot_title_saved_1
poke16 0x01c824 <- 0x2044  aux boot_title_saved_2
poke16 0x01c826 <- 0x2020  aux boot_title_saved_3
data   0x4010e0 +0xe50  data_port throw_victim_keyframes PLACED (tenant at 0x13; host block 0xb19f8 untouched) <- vsav2 0x0ca1ca (1 fixes)
poke32 0x0be2c6 <- 0x4010e0  data_port throw_victim_keyframes ptr-table 0xbe27a row 0x13
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
data   0x00b728 +0x40  data_port voice_borrow_candidates_a <- vsav2 0x009fea (0 fixes)
data   0x00c028 +0x40  data_port voice_borrow_voicenums_b <- vsav2 0x00a8ea (0 fixes)
data   0x401f30 +0xee0  data_port capture_kf_bulleta PLACED (slot_rows; vanilla block 0x92c4a untouched) <- vsav2 0x0a1dbe (0 fixes)
poke32 0x0be27a <- 0x401f30  data_port capture_kf_bulleta ptr-table 0xbe27a row 0x00 (slot_rows)
data   0x402e10 +0x1240  data_port capture_kf_demitri PLACED (slot_rows; vanilla block 0x94954 untouched) <- vsav2 0x0a3d88 (0 fixes)
poke32 0x0be27e <- 0x402e10  data_port capture_kf_demitri ptr-table 0xbe27a row 0x01 (slot_rows)
data   0x404050 +0xdc0  data_port capture_kf_gallon PLACED (slot_rows; vanilla block 0x968de untouched) <- vsav2 0x0a61d2 (0 fixes)
poke32 0x0be282 <- 0x404050  data_port capture_kf_gallon ptr-table 0xbe27a row 0x02 (slot_rows)
data   0x404e10 +0x1f30  data_port capture_kf_victor PLACED (slot_rows; vanilla block 0x98c28 untouched) <- vsav2 0x0a8824 (0 fixes)
poke32 0x0be286 <- 0x404e10  data_port capture_kf_victor ptr-table 0xbe27a row 0x03 (slot_rows)
data   0x406d40 +0x1df0  data_port capture_kf_zabel PLACED (slot_rows; vanilla block 0x9baea untouched) <- vsav2 0x0abc56 (0 fixes)
poke32 0x0be28a <- 0x406d40  data_port capture_kf_zabel ptr-table 0xbe27a row 0x04 (slot_rows)
poke32 0x0be2a6 <- 0x406d40  data_port capture_kf_zabel ptr-table 0xbe27a row 0x0b (slot_rows)
data   0x408b30 +0x12a8  data_port capture_kf_morrigan PLACED (slot_rows; vanilla block 0xa0010 untouched) <- vsav2 0x0aedb4 (0 fixes)
poke32 0x0be28e <- 0x408b30  data_port capture_kf_morrigan ptr-table 0xbe27a row 0x05 (slot_rows)
data   0x409de0 +0x3a0  data_port capture_kf_anakaris PLACED (slot_rows; vanilla block 0xa204e untouched) <- vsav2 0x0b119a (0 fixes)
poke32 0x0be292 <- 0x409de0  data_port capture_kf_anakaris ptr-table 0xbe27a row 0x06 (slot_rows)
data   0x40a180 +0x30a0  data_port capture_kf_felicia PLACED (slot_rows; vanilla block 0xa3990 untouched) <- vsav2 0x0b2bac (0 fixes)
poke32 0x0be296 <- 0x40a180  data_port capture_kf_felicia ptr-table 0xbe27a row 0x07 (slot_rows)
data   0x40d220 +0x940  data_port capture_kf_bishamon PLACED (slot_rows; vanilla block 0xa74aa untouched) <- vsav2 0x0b6f22 (0 fixes)
poke32 0x0be29a <- 0x40d220  data_port capture_kf_bishamon ptr-table 0xbe27a row 0x08 (slot_rows)
poke32 0x0be2da <- 0x40d220  data_port capture_kf_bishamon ptr-table 0xbe27a row 0x18 (slot_rows)
data   0x40db60 +0xa60  data_port capture_kf_aulbath PLACED (slot_rows; vanilla block 0xa8aec untouched) <- vsav2 0x0b8724 (0 fixes)
poke32 0x0be29e <- 0x40db60  data_port capture_kf_aulbath ptr-table 0xbe27a row 0x09 (slot_rows)
data   0x40e5c0 +0x1510  data_port capture_kf_sasquatch PLACED (slot_rows; vanilla block 0xaa2e2 untouched) <- vsav2 0x0ba152 (0 fixes)
poke32 0x0be2a2 <- 0x40e5c0  data_port capture_kf_sasquatch ptr-table 0xbe27a row 0x0a (slot_rows)
data   0x40fad0 +0xb80  data_port capture_kf_qbee PLACED (slot_rows; vanilla block 0xac9ce untouched) <- vsav2 0x0bcbb6 (0 fixes)
poke32 0x0be2aa <- 0x40fad0  data_port capture_kf_qbee ptr-table 0xbe27a row 0x0c (slot_rows)
data   0x410650 +0x618  data_port capture_kf_leilei PLACED (slot_rows; vanilla block 0xae324 untouched) <- vsav2 0x0be728 (0 fixes)
poke32 0x0be2ae <- 0x410650  data_port capture_kf_leilei ptr-table 0xbe27a row 0x0d (slot_rows)
data   0x410c70 +0x11b0  data_port capture_kf_lilith PLACED (slot_rows; vanilla block 0xafbfe untouched) <- vsav2 0x0c010e (0 fixes)
poke32 0x0be2b2 <- 0x410c70  data_port capture_kf_lilith ptr-table 0xbe27a row 0x0e (slot_rows)
data   0x411e20 +0x1cf0  data_port capture_kf_jedah PLACED (slot_rows; vanilla block 0xb19f8 untouched) <- vsav2 0x0c2430 (0 fixes)
poke32 0x0be2b6 <- 0x411e20  data_port capture_kf_jedah ptr-table 0xbe27a row 0x0f (slot_rows)
data   0x413b10 +0x160  sound_table don_sfx_records <- vsav2 0x0cb01a (44 entries; kept ['0x110@1', '0x111@2', '0x112@3', '0x058@4', '0x059@5', '0x05a@6', '0x05b@7', '0x05c@8', '0x05d@9', '0x05e@10', '0x05f@11', '0x060@12', '0x061@13', '0x062@14', '0x063@15', '0x064@16', '0x065@17', '0x066@18', '0x067@19', '0x152@21', '0x119@22', '0x068@23', '0x069@24', '0x06a@25', '0x06b@26', '0x06c@27', '0x06d@28', '0x06e@29', '0x06f@30', '0x070@31', '0x071@32', '0x072@33', '0x073@34', '0x074@35', '0x075@36', '0x076@37', '0x077@38', '0x078@39', '0x079@40', '0x07a@41', '0x07b@42']; zeroed 2 unplayable ids; remapped [(4, '0x700', '0x58'), (5, '0x701', '0x59'), (6, '0x702', '0x5a'), (7, '0x703', '0x5b'), (8, '0x704', '0x5c'), (9, '0x705', '0x5d'), (10, '0x706', '0x5e'), (11, '0x707', '0x5f'), (12, '0x708', '0x60'), (13, '0x709', '0x61'), (14, '0x70a', '0x62'), (15, '0x70b', '0x63'), (16, '0x70c', '0x64'), (17, '0x70d', '0x65'), (18, '0x70e', '0x66'), (19, '0x70f', '0x67'), (23, '0x710', '0x68'), (24, '0x711', '0x69'), (25, '0x712', '0x6a'), (26, '0x713', '0x6b'), (27, '0x714', '0x6c'), (28, '0x715', '0x6d'), (29, '0x716', '0x6e'), (30, '0x717', '0x6f'), (31, '0x718', '0x70'), (32, '0x719', '0x71'), (33, '0x71a', '0x72'), (34, '0x71b', '0x73'), (35, '0x71c', '0x74'), (36, '0x71d', '0x75'), (37, '0x71e', '0x76'), (38, '0x71f', '0x77'), (39, '0x750', '0x78'), (40, '0x751', '0x79'), (41, '0x752', '0x7a'), (42, '0x753', '0x7b')])
poke32 0x0bf466 <- 0x413b10  sound_table don_sfx_records per-char ptr row 0x13 (was 0x9a630)
data   0x0211e4        select_wheel roster21: TABLE B in place, 28 bytes over 3 new rows + 5 inbound edges
# select_wheel roster21: version_text 'M16' -> 3 glyph entries at screen (324,202), pal row 0x19, codes 0x1fe40+ (authored tiles via wheel_bank5.json)
data   0x413c70 +0x6c  select_wheel roster21 coord list (18 vanilla + 3 new + 3 cell outlines + 3 version glyphs)
data   0x413ce0 +0x76  select_wheel roster21 record (count 17->26, budget 0x55 CARRIED OVER, cptr -> 0x413c70)
poke32 0x2689fe <- 0x413ce0  select_wheel roster21 record ptr (was 0x272a68; the record's ONLY referrer — vanilla record and list are untouched)
code   0x05fb22 +4     select_wheel roster21: highlight base row 0x10 <- (165,77) (was the row 0x00 alias)
code   0x05fb26 +4     select_wheel roster21: highlight base row 0x11 <- (191,65) (was the row 0x01 alias)
code   0x05fb2e +4     select_wheel roster21: highlight base row 0x13 <- (217,77) (was the row 0x03 alias)
# select_wheel roster21: 3 highlight base rows written in place (32-row aliased pc-rel table 0x5fae2; the vs2 precedent — its variant half is un-aliased for its newcomers)
poke32 0x268b42 <- 0x2728e6  select_wheel roster21: mirror highlight row 0x10 = host row 0x0f ring (ring_rows)
poke32 0x268b46 <- 0x2728e6  select_wheel roster21: mirror highlight row 0x11 = host row 0x0f ring (ring_rows)
poke32 0x268b4e <- 0x2728e6  select_wheel roster21: mirror highlight row 0x13 = host row 0x0f ring (ring_rows)
# select_wheel roster21: 3 ring rows poked (host row 0x0f records verbatim; P1/P2 for non-tenant cells + mirror for all)
# select_wheel roster21: 3 cell outline sprites (4x3, pal 0x19 pen 0) at 0x1f800+ (rendered by build_gfx from the medallions' alpha)
code   0x05f8b2 +6     select_wheel roster21: drawer bank word #$2000 -> #$3000 (bank 5) in the select init — writes ONLY $FFB818 (measured)
# select_wheel roster21: 85 host + 18 vs2 tiles -> wheel_bank5.json (group C upper bank, placed by build_gfx --wheel-bank5)
data   0x3a3b20 +0x20  select_wheel roster21: medallion pal row 0x19 (cell 0x10) <- vs2 0x3bb19c; entry attr re-palmed
data   0x3a3b40 +0x20  select_wheel roster21: medallion pal row 0x1a (cell 0x11) <- vs2 0x3bb15c; entry attr re-palmed
data   0x3a3ac0 +0x20  select_wheel roster21: medallion pal row 0x16 (cell 0x13) <- vs2 0x3bafdc; entry attr re-palmed
code   0x3ff9b0 +0x28  select_wheel roster21: march mid-row retarget 0x16/0x19 -> 0x02 (dest computation 0x2b598 jsr-routed)
code   0x3ff9e0 +0x28  select_wheel roster21: march mid-row retarget 0x16/0x19 -> 0x02 (dest computation 0x2b7d8 jsr-routed)
data   0x413d60 +0x1c  select_records portrait/p1 coord list (7 pairs, vs2 0x3036f8)
data   0x413d80 +0x26  select_records portrait/p1 record (vs2 0x2a63f0, 7 entries, budget 0x5b = vs2's own)
poke32 0x267476 <- 0x413d80  select_records portrait/p1 array row 0x13 (was 0x2719da, the base-half alias)
data   0x413db0 +0x1c  select_records portrait/p2 coord list (7 pairs, vs2 0x303714)
data   0x413dd0 +0x26  select_records portrait/p2 record (vs2 0x2a6416, 7 entries, budget 0x5b = vs2's own)
poke32 0x2674f6 <- 0x413dd0  select_records portrait/p2 array row 0x13 (was 0x271dec, the base-half alias)
data   0x413e00 +0x4  select_records name_banner/p1 coord list (1 pairs, vs2 0x303734)
data   0x413e10 +0xe  select_records name_banner/p1 record (vs2 0x2a657e, 1 entries, budget 0xa = vs2's own)
poke32 0x2675f6 <- 0x413e10  select_records name_banner/p1 array row 0x13 (was 0x272172, the base-half alias)
data   0x413e20 +0x8  select_records name_banner/p2 coord list (2 pairs, vs2 0x303da4)
data   0x413e30 +0x12  select_records name_banner/p2 record (vs2 0x2a76a4, 2 entries, budget 0x3 = vs2's own)
poke32 0x267676 <- 0x413e30  select_records name_banner/p2 array row 0x13 (was 0x273080, the base-half alias)
data   0x413e50 +0x14  select_records splash_p1/p1 coord list (5 pairs, vs2 0x3043a4)
data   0x413e70 +0x1e  select_records splash_p1/p1 record (vs2 0x2a7f68, 5 entries, budget 0x4b = vs2's own)
poke32 0x2672f6 <- 0x413e70  select_records splash_p1/p1 array row 0x13 (was 0x2734e8, the base-half alias)
data   0x413e90 +0x14  select_records splash_p2/p1 coord list (5 pairs, vs2 0x3043b8)
data   0x413eb0 +0x1e  select_records splash_p2/p1 record (vs2 0x2a7f86, 5 entries, budget 0x4b = vs2's own)
poke32 0x267376 <- 0x413eb0  select_records splash_p2/p1 array row 0x13 (was 0x27382e, the base-half alias)
data   0x413ed0 +0x8c  select_records win_quote/p1 coord list (35 pairs, vs2 0x30506c)
data   0x413f60 +0x96  select_records win_quote/p1 record (vs2 0x2a8cf8, 35 entries, budget 0xa7 = vs2's own)
poke32 0x2673f6 <- 0x413f60  select_records win_quote/p1 array row 0x13 (was 0x273d3c, the base-half alias)
poke32 0x268a4e <- 0x2724a2  select_records highlight/p1 array row 0x13 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x272594)
poke32 0x268ace <- 0x2726ce  select_records highlight/p2 array row 0x13 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x2727c0)
# select_records: 0 bank-1 tile placements -> select_tiles.json (only the composed records' art; the slot-0x0F splash/win-quote families are NOT placed, so that Jedah art stays vanilla)
# select_records: 271 native bank-1 tiles -> select_bank5.json (copied vs2 -> group C bank 5 by build_gfx; the drawer's bank is thunk-gated per hover)
code   0x3ffa10 +0x18  site_thunk select_companion_tbl_a; site 0x0845ec jsr-routed
code   0x3ffa30 +0x18  site_thunk select_companion_tbl_b; site 0x0845f8 jsr-routed
code   0x3ffa50 +0x22  site_thunk select_companion_resolve_s1; site 0x084602 jsr-routed
code   0x3ffa80 +0x22  site_thunk select_companion_resolve_s2; site 0x084624 jsr-routed
code   0x3ffab0 +0x3c  site_thunk accent_color_aware_0; site 0x02ad82 jsr-routed
code   0x3ffaf0 +0x3c  site_thunk accent_color_aware_1; site 0x02ad94 jsr-routed
code   0x3ffb30 +0x3c  site_thunk accent_color_aware_2; site 0x02b342 jsr-routed
code   0x3ffb70 +0x3c  site_thunk accent_color_aware_3; site 0x02b7e8 jsr-routed
code   0x3ffbb0 +0x2a  site_thunk ls_freeze_vs2_victim; site 0x023ad8 jsr-routed
code   0x3ffbe0 +0x24  site_thunk ls_freeze_vs2_attacker; site 0x023ade jsr-routed
code   0x3ffc10 +0x16  site_thunk es_type51_dispatch; site 0x0185ca jsr-routed
# site_thunk name_bank_variant_id: body deferred to the 0x05fce0 chain (30 bytes)
# site_thunk splash_bank_variant_id: body deferred to the 0x06c0e0 chain (30 bytes)
# site_thunk winquote_bank_variant_id: body deferred to the 0x05f328 chain (22 bytes)
code   0x3ffc30 +0x7e  site_thunk select_sword_pal_variant_id; site 0x05f9d0 jsr-routed
data   0x414000 +0x140  site_thunk select_pal_variant_id data block <- vsav2 0x3c2a3c
# site_thunk select_pal_variant_id: body deferred to the 0x05f146 chain (56 bytes)
code   0x3ffcb0 +0x22  site_thunk voice_borrow_keep_tenant; site 0x00aef2 jsr-routed
code   0x3ffce0 +0x1e  site_thunk oboro_select_hook; site 0x020b9c jsr-routed
# site_thunk random_select_bound: roster_subst -> ['0x10', '0x11', '0x13'] (bound 15+3)
code   0x3ffd00 +0xe  site_thunk random_select_bound; site 0x020c74 jmp-routed
# site_thunk random_select_roster: roster_subst -> ['0x10', '0x11', '0x13'] (bound 15+3)
code   0x3ffd10 +0x1a  site_thunk random_select_roster; site 0x020c80 jmp-routed
code   0x3ffd30 +0x5e  site_thunk hitclass_map_extend; site 0x01a888 jmp-routed
code   0x08459c +0x2  code_word select_companion_entry_0f (slot entry -> 0046)
code   0x0282fa +0x2  code_word obj_bank_word_slot (slot entry -> 1000)
code   0x05f24c +0x2  code_word win_pos_x_slot (slot entry -> 00f0)
code   0x05f24e +0x2  code_word win_pos_y_slot (slot entry -> 0098)
code   0x00aef8 +0x2  code_word voice_borrow_site_pad (0382 -> 4e71)
code   0x003bf4 +0x2  code_word don_kernel_voice_e0 (0320 -> 00d9)
code   0x003c60 +0x2  code_word don_kernel_voice_e1 (0321 -> 00da)
code   0x003ccc +0x2  code_word don_kernel_voice_e2 (0322 -> 00db)
code   0x003d36 +0x2  code_word don_kernel_voice_e3 (0323 -> 00dc)
# stage 1: Jedah hitbox block 0x091E58+0x0 (base 0x91f98 comp 0x91e58)
# table_fix: region x026142 len 0x1400 -> 0x1440 (merged vanilla bank table; tenant rows written per tenant)
# layout group at 0x414140+0x79c6: code@0x414140, x057456@0x416906; -0x14 gap bytes recycled
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
data_file 0x42d6a0 +0x1e800  donovan anim (from vsav2 0x245872)
data_file 0x44bea0 +0x190  donovan aux0_0 (from vsav2 0x334170)
data_file 0x44c030 +0xe620  donovan aux0_1 (from vsav2 0x336560)
# code+0x9c: pcrel16 -> x057456@0x574b0 (disp 0x2784 -> 0x2784 after placement)
# code+0x102: pcrel16 -> x057456@0x574b0 (disp 0x271e -> 0x271e after placement)
# code+0x15a: pcrel16 -> x057456@0x574b6 (disp 0x26cc -> 0x26cc after placement)
# code+0x1a4: pcrel16 -> x057456@0x574b6 (disp 0x2682 -> 0x2682 after placement)
# code+0x2f4: pcrel16 -> x057456@0x574b0 (disp 0x252c -> 0x252c after placement)
code   0x3fff70 farm-port stub for 0x2916c (param at 0x3fff50, common 0x29f4a)
code   0x3fff90 farm-port stub for 0x29184 (param at 0x3fff80, common 0x29f4a)
code   0x3fffb0 farm-port stub for 0x2918c (param at 0x3fffa0, common 0x29f4a)
code   0x3fffc0 slot-clearing alloc wrapper for 0x15702 -> 0x16fba (0x80 cleared, +8 preserved)
# code+0x9ac: pcrel16 -> x057456@0x574b0 (disp 0x1e74 -> 0x1e74 after placement)
# code+0xd3a: pcrel16 -> x057456@0x574b0 (disp 0x1ae6 -> 0x1ae6 after placement)
# code+0xfe2: pcrel16 -> x057456@0x574b0 (disp 0x183e -> 0x183e after placement)
# code+0x10da: pcrel16 -> x057456@0x574b0 (disp 0x1746 -> 0x1746 after placement)
code   0x46a630 sound stub for 0x4ddc (vsavj sfx id 0x84)
code   0x46a650 sound stub for 0x4f48 (vsavj sfx id 0x8b)
# code+0x141a: pcrel16 -> x057456@0x574b0 (disp 0x1406 -> 0x1406 after placement)
# code+0x142a: pcrel16 -> x057456@0x574b0 (disp 0x13f6 -> 0x13f6 after placement)
# code+0x151a: pcrel16 -> x057456@0x574b0 (disp 0x1306 -> 0x1306 after placement)
# code+0x18d0: pcrel16 -> x057456@0x574b0 (disp 0xf50 -> 0xf50 after placement)
# code+0x18e0: pcrel16 -> x057456@0x574b0 (disp 0xf40 -> 0xf40 after placement)
code   0x46a670 sound stub for 0x4e92 (vsavj sfx id 0x93)
# code+0x197c: pcrel16 -> x057456@0x574b0 (disp 0xea4 -> 0xea4 after placement)
# code+0x1a38: pcrel16 -> x057456@0x574c2 (disp 0xdfa -> 0xdfa after placement)
# code+0x1a46: pcrel16 -> x057456@0x574c2 (disp 0xdec -> 0xdec after placement)
# code+0x1a86: pcrel16 -> x057456@0x574c2 (disp 0xdac -> 0xdac after placement)
# code+0x1b94: pcrel16 -> x057456@0x574b0 (disp 0xc8c -> 0xc8c after placement)
# code+0x1c94: pcrel16 -> x057456@0x574b0 (disp 0xb8c -> 0xb8c after placement)
# code+0x1f06: pcrel16 -> x057456@0x574bc (disp 0x926 -> 0x926 after placement)
code   0x46a690 sound stub for 0x4ec6 (vsavj sfx id 0x95)
code   0x46a6b0 sound stub for 0x4e10 (vsavj sfx id 0x85)
# code+0x20de: pcrel16 -> x057456@0x574b0 (disp 0x742 -> 0x742 after placement)
# code+0x2192: pcrel16 -> x057456@0x574b0 (disp 0x68e -> 0x68e after placement)
# code+0x21aa: pcrel16 -> x057456@0x574b0 (disp 0x676 -> 0x676 after placement)
# code+0x2226: pcrel16 -> x057456@0x574b0 (disp 0x5fa -> 0x5fa after placement)
# code+0x2392: pcrel16 -> code@0x57024 (disp 0x2 -> 0x2 after placement)
# code+0x249c: pcrel16 -> x057456@0x574b0 (disp 0x384 -> 0x384 after placement)
code   0x46a6d0 sound stub for 0x4e5e (vsavj sfx id 0x91)
code   0x46a6f0 sound stub for 0x4e78 (vsavj sfx id 0x92)
# code+0x253c: pcrel16 -> x057456@0x574b0 (disp 0x2e4 -> 0x2e4 after placement)
# code+0x2546: pcrel16 -> code@0x571d8 (disp 0x2 -> 0x2 after placement)
# code+0x990: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0xa4c: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0xb88: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0xba6: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0xbc4: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0xbfe: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0xce6: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0xd04: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0x1124: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0x1332: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0x1350: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0x1564: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0x176a: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0x1788: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0x1a1c: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0x1f6c: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0x1f8a: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0x26ca: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0x26f4: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# code+0x273e: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
code   0x3ffff0 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c00440002, rts)
# code+0x966: owner_tag stamp_b_d16 type 68 -> jsr 0x3ffff0 (huitzil id 0x10)
# code+0xa22: owner_tag stamp_b_d16 type 68 -> jsr 0x3ffff0 (huitzil id 0x10)
code   0x46a710 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c00450002, rts)
# code+0xdf0: owner_tag stamp_b_d16 type 69 -> jsr 0x46a710 (huitzil id 0x10)
# code+0xe20: owner_tag stamp_b_d16 type 69 -> jsr 0x46a710 (huitzil id 0x10)
code   0x46a720 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c00460002, rts)
# code+0x1070: owner_tag stamp_b_d16 type 70 -> jsr 0x46a720 (huitzil id 0x10)
# code+0x14b0: owner_tag stamp_b_d16 type 70 -> jsr 0x46a720 (huitzil id 0x10)
code   0x46a730 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c00470002, rts)
# code+0x1950: owner_tag stamp_b_d16 type 71 -> jsr 0x46a730 (huitzil id 0x10)
code   0x46a740 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c00480002, rts)
# code+0x2026: owner_tag stamp_b_d16 type 72 -> jsr 0x46a740 (huitzil id 0x10)
# code+0x2048: owner_tag stamp_b_d16 type 72 -> jsr 0x46a740 (huitzil id 0x10)
# code+0x13bc: data_in_code reroute -> helper 0x46a760, table 0x46a750 (DATA view of vsav2 0x056074; FG capture-pose random table (native draws seqs 1/3/5))
# code+0x1390: data_in_code reroute -> helper 0x46a780, table 0x46a770 (DATA view of vsav2 0x056064; FG capture-pose table 2 (seqs 0x56-0x59))
# code+0x17c8: data_in_code reroute -> helper 0x46a7a0, table 0x46a790 (DATA view of vsav2 0x05649c; capture-pose table 3 (seqs 0x56-0x59 twin))
# code+0x17f4: data_in_code reroute -> helper 0x46a7c0, table 0x46a7b0 (DATA view of vsav2 0x0564ac; capture-pose table 4 (01/03/05 twin))
code_file 0x414140 +0x27c6  donovan code (from vsav2 0x054C90)
data_file 0x45a650 +0x32b2  donovan hitbox (from vsav2 0x0C4250)
# hitbox_proj+0x17d: region_fix 52 -> 06 (trap dome hit record 1: class 0x52 -> 0x06 (vs2-alias-proven; routes vsavj electric-shake 0x23AC8))
# hitbox_proj+0x19d: region_fix 52 -> 06 (trap dome hit record 2: class 0x52 -> 0x06 (vs2-alias-proven))
data_file 0x45d910 +0x3c6  donovan hitbox_proj (from vsav2 0x0D05C0)
code   0x46a7d0 ILLEGAL  TRIPWIRE for unresolved 0x2cd38
# x022400+0x112: unresolved 0x2cd38 -> tripwire 0x46a7d0
# bank_ref 0xd8998 -> 0xbe7fa (delta rule, 16B byte-identical)
code   0x46a7e0 ILLEGAL  TRIPWIRE for unresolved 0x7f5f4
# x022400+0xa82: unresolved 0x7f5f4 -> tripwire 0x46a7e0
code   0x46a7f0 ILLEGAL  TRIPWIRE for unresolved 0x82480
# x022400+0xada: unresolved 0x82480 -> tripwire 0x46a7f0
# bank_ref 0xd9638 -> 0xbf49a (delta rule, known table base)
code   0x46a800 ILLEGAL  TRIPWIRE for unresolved 0x828fe
# x022400+0xb66: unresolved 0x828fe -> tripwire 0x46a800
# bank_ref 0xd8998 -> 0xbe7fa (delta rule, 16B byte-identical)
code   0x46a810 ILLEGAL  TRIPWIRE for unresolved 0xbdb0
# x022400+0x12ac: unresolved 0xbdb0 -> tripwire 0x46a810
# x022400+0x12fa: unresolved 0x2cd38 -> tripwire 0x46a7d0
code   0x46a820 ILLEGAL  TRIPWIRE for unresolved 0x8278c
# x022400+0x14c0: unresolved 0x8278c -> tripwire 0x46a820
code   0x46a830 ILLEGAL  TRIPWIRE for unresolved 0x7b368
# x022400+0x15c8: unresolved 0x7b368 -> tripwire 0x46a830
code   0x46a840 ILLEGAL  TRIPWIRE for unresolved 0x3d1c
# x022400+0x662: unresolved 0x3d1c -> tripwire 0x46a840
code   0x46a850 ILLEGAL  TRIPWIRE for unresolved 0x3dc6
# x022400+0x696: unresolved 0x3dc6 -> tripwire 0x46a850
code   0x46a860 ILLEGAL  TRIPWIRE for unresolved 0x3e70
# x022400+0x80c: unresolved 0x3e70 -> tripwire 0x46a860
# x022400+0x86c: unresolved 0x3d1c -> tripwire 0x46a840
code   0x46a870 ILLEGAL  TRIPWIRE for unresolved 0x3c44
# x022400+0x1078: unresolved 0x3c44 -> tripwire 0x46a870
code   0x46a880 ILLEGAL  TRIPWIRE for unresolved 0x3cb0
# x022400+0x13a0: unresolved 0x3cb0 -> tripwire 0x46a880
code   0x46a890 ILLEGAL  TRIPWIRE for unresolved 0x3a28
# x022400+0x13e0: unresolved 0x3a28 -> tripwire 0x46a890
# x022400+0x13ee: unresolved 0x3a28 -> tripwire 0x46a890
code   0x46a8a0 ILLEGAL  TRIPWIRE for unresolved 0x3980
# x022400+0x1404: unresolved 0x3980 -> tripwire 0x46a8a0
code   0x46a8b0 ILLEGAL  TRIPWIRE for unresolved 0x41be
# x022400+0x14ce: unresolved 0x41be -> tripwire 0x46a8b0
# x022400+0x82: char-id imm 0x10 -> 0x10
# x022400+0x1618: ESCAPE TRIPWIRE for unresolved pcrel target 0x24d12
# x022400+0x1624: ESCAPE TRIPWIRE for unresolved pcrel target 0x275e4
# pcrel_escape_fix x022400: 118 escapes -> 11 trampolines (2 tripwired), pad 0x1600..0x1780
code_file 0x41bb10 +0x1780  donovan x022400 (from vsav2 0x022400)
# pcrel_escape_fix x02592a: 89 escapes -> 35 trampolines (0 tripwired), pad 0x456..0x576
code_file 0x41d290 +0x576  donovan x02592a (from vsav2 0x02592A)
# x026142+0x1414: bank table row 0x13 <- 0x1000 (bank 4, WIDE encoding; vanilla row was 0x2000) — tenant-driven
# x026142+0x140e: bank table row 0x10 <- 0x1000 (bank 4, WIDE encoding; vanilla row was 0x6000) — tenant-driven
# x026142+0x1410: bank table row 0x11 <- 0x1000 (bank 4, WIDE encoding; vanilla row was 0x6000) — tenant-driven
# x026142+0x13ee: table_fix 48 bytes (merged vanilla bank table; tenant rows written per tenant)
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
code_file 0x41d810 +0x14a0  donovan x026142 (from vsav2 0x026142)
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
code_file 0x41ecb0 +0xe00  donovan x028122 (from vsav2 0x028122)
code   0x46a8c0 slot-clearing alloc wrapper for 0x1572e -> 0x16fe6 (0x80 cleared, +8 preserved)
code   0x46a900 farm-port stub for 0x2915c (param at 0x46a8f0, common 0x29f4a)
code   0x46a920 farm-port stub for 0x29164 (param at 0x46a910, common 0x29f4a)
code   0x46a930 sound stub for 0x4f96 (vsavj sfx id 0xa1)
code   0x46a950 ILLEGAL  TRIPWIRE for unresolved 0x4223c
# x057456+0x3b42: unresolved 0x4223c -> tripwire 0x46a950
code   0x46a960 ILLEGAL  TRIPWIRE for unresolved 0x42cee
# x057456+0x421a: unresolved 0x42cee -> tripwire 0x46a960
code   0x46a970 ILLEGAL  TRIPWIRE for unresolved 0x448d4
# x057456+0x50cc: unresolved 0x448d4 -> tripwire 0x46a970
# x057456+0x418e: char-id imm 0x10 -> 0x10
# x057456+0x1f36: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H own zone): vs2 bank 3 -> WIDE bank 4)
# x057456+0x2468: type_renumber stamp_l_ind type 114 -> 124 (huitzil's own number; site 0x5e542)
# x057456+0x2b7e: type_renumber stamp_l_ind type 114 -> 124 (huitzil's own number; site 0x5e542)
# x057456+0x2bf0: type_renumber stamp_l_ind type 114 -> 124 (huitzil's own number; site 0x5e542)
# x057456+0x2c06: type_renumber stamp_l_ind type 114 -> 124 (huitzil's own number; site 0x5e542)
# x057456+0x2d18: type_renumber stamp_l_ind type 114 -> 124 (huitzil's own number; site 0x5e542)
# x057456+0x2dee: type_renumber stamp_l_ind type 114 -> 124 (huitzil's own number; site 0x5e542)
# x057456+0x2fd0: type_renumber stamp_l_ind type 114 -> 124 (huitzil's own number; site 0x5e542)
# x057456+0x3774: type_renumber stamp_l_ind type 114 -> 124 (huitzil's own number; site 0x5e542)
# x057456+0x38bc: type_renumber stamp_l_ind type 114 -> 124 (huitzil's own number; site 0x5e542)
# x057456+0x38e8: type_renumber stamp_l_ind type 114 -> 124 (huitzil's own number; site 0x5e542)
# x057456+0x3ac6: type_renumber stamp_l_ind type 114 -> 124 (huitzil's own number; site 0x5e542)
# x057456+0x3c: type_renumber stamp_l_ind type 115 -> 126 (huitzil's own number; site 0x5e542)
# x057456+0x1f2a: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# x057456+0x2014: type_renumber stamp_l_ind type 118 -> 132 (huitzil's own number; site 0x5e542)
code   0x46a980 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c00400002, rts)
# x057456+0x8fc: owner_tag stamp_b_d16 type 64 -> jsr 0x46a980 (huitzil id 0x10)
code   0x46a990 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c00410002, rts)
# x057456+0xa24: owner_tag stamp_b_d16 type 65 -> jsr 0x46a990 (huitzil id 0x10)
code   0x46a9a0 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c00420002, rts)
# x057456+0x14ce: owner_tag stamp_b_d16 type 66 -> jsr 0x46a9a0 (huitzil id 0x10)
code   0x46a9b0 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c00430002, rts)
# x057456+0x18f6: owner_tag stamp_b_d16 type 67 -> jsr 0x46a9b0 (huitzil id 0x10)
code   0x46a9c0 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c003e0002, rts)
# x057456+0x29c4: owner_tag stamp_b_d16 type 62 -> jsr 0x46a9c0 (huitzil id 0x10)
code   0x46a9d0 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c003f0002, rts)
# x057456+0x2b4a: owner_tag stamp_b_d16 type 63 -> jsr 0x46a9d0 (huitzil id 0x10)
code   0x46a9e0 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c004b0002, rts)
# x057456+0x2b56: owner_tag stamp_b_d16 type 75 -> jsr 0x46a9e0 (huitzil id 0x10)
code   0x46a9f0 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c003d0002, rts)
# x057456+0x39fe: owner_tag stamp_b_d16 type 61 -> jsr 0x46a9f0 (huitzil id 0x10)
code   0x46aa00 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_b_d16 197c00490002, rts)
# x057456+0x4624: owner_tag stamp_b_d16 type 73 -> jsr 0x46aa00 (huitzil id 0x10)
code   0x46aa10 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_l_ind 28bc01014200, rts)
# x057456+0x4d12: owner_tag stamp_l_ind type 66 -> jsr 0x46aa10 (huitzil id 0x10)
code   0x46aa20 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_l_ind 28bc01004202, rts)
# x057456+0x4ddc: owner_tag stamp_l_ind type 66 -> jsr 0x46aa20 (huitzil id 0x10)
code_file 0x416906 +0x5200  donovan x057456 (from vsav2 0x057456)
code   0x46aa30 ILLEGAL  TRIPWIRE for unresolved 0x12f484
# x05c800+0x152a: unresolved 0x12f484 -> tripwire 0x46aa30
# x05c800+0x16a4: unresolved 0x12f484 -> tripwire 0x46aa30
code   0x46aa40 ILLEGAL  TRIPWIRE for unresolved 0x167bf4
# x05c800+0x2622: unresolved 0x167bf4 -> tripwire 0x46aa40
# x05c800+0x2a20: unresolved 0x167bf4 -> tripwire 0x46aa40
code   0x46aa50 ILLEGAL  TRIPWIRE for unresolved 0x17f176
# x05c800+0x2ae4: unresolved 0x17f176 -> tripwire 0x46aa50
# x05c800+0x3034: unresolved 0x17f176 -> tripwire 0x46aa50
code   0x46aa60 ILLEGAL  TRIPWIRE for unresolved 0x181592
# x05c800+0x3072: unresolved 0x181592 -> tripwire 0x46aa60
# x05c800+0x1456: char-id imm 0x10 -> 0x10
# x05c800+0x738: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 (Jedah band) / WIDE bank 4)
# x05c800+0x58d4: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (a4 form): vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x05c800+0x5994: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (a4 form): vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
code   0x46aa70 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_l_ind 28bc01003b22, rts)
# x05c800+0x83a: owner_tag stamp_l_ind type 59 -> jsr 0x46aa70 (huitzil id 0x10)
# pcrel_escape_fix x05c800: 2 escapes -> 1 trampolines (0 tripwired), pad 0x6a00..0x6a20
code_file 0x41fab0 +0x6a20  donovan x05c800 (from vsav2 0x05C800)
code_file 0x4264d0 +0x280  donovan x0672d0 (from vsav2 0x0672D0)
code_file 0x426750 +0x2f6  donovan x067550 (from vsav2 0x067550)
code   0x46aa80 sound stub for 0x4fb0 (vsavj sfx id 0xa0)
code   0x46aaa0 sound stub for 0x4fca (vsavj sfx id 0xa5)
code_file 0x3ffd90 +0x1ba  donovan x067846 (from vsav2 0x067846)
code_file 0x426a50 +0x60c  donovan x067a00 (from vsav2 0x067A00)
# x06800c+0x354: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x396: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x3de: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x422: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x348: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# x06800c+0x38a: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# x06800c+0x3d2: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
# x06800c+0x416: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
code_file 0x427060 +0x44c  donovan x06800c (from vsav2 0x06800C)
code   0x46aac0 sound stub for 0x4f2e (vsavj sfx id 0x199)
code_file 0x4274b0 +0x310  donovan x068458 (from vsav2 0x068458)
code_file 0x4277c0 +0x264  donovan x068768 (from vsav2 0x068768)
code   0x46aae0 sound stub for 0x4efa (vsavj sfx id 0x90)
code_file 0x427a30 +0x2ac  donovan x0689cc (from vsav2 0x0689CC)
code   0x46ab00 +0x40  patched clone of 0x5459a for vs2 0x5c77e (unmasked set-anim entry; false byte-matc)
code   0x46ab40 sound stub for 0x4f62 (vsavj sfx id 0x7f)
code_file 0x427ce0 +0x3ce  donovan x068c78 (from vsav2 0x068C78)
# x069046+0x260: type_renumber stamp_l_ind type 114 -> 124 (huitzil's own number; site 0x5e542)
code   0x46ab60 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_l_ind 28bc01004206, rts)
# x069046+0x4a: owner_tag stamp_l_ind type 66 -> jsr 0x46ab60 (huitzil id 0x10)
code   0x46ab70 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_l_ind 28bc01004204, rts)
# x069046+0x130: owner_tag stamp_l_ind type 66 -> jsr 0x46ab70 (huitzil id 0x10)
code_file 0x4280b0 +0x2b0  donovan x069046 (from vsav2 0x069046)
# x0692f6+0x19a: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (H farm zone): vs2 bank 3 -> WIDE bank 4)
# x0692f6+0x18e: type_renumber stamp_b_d16 type 115 -> 126 (huitzil's own number; site 0x5e542)
code_file 0x428360 +0x368  donovan x0692f6 (from vsav2 0x0692F6)
# x06965e+0xac: type_renumber stamp_l_ind type 114 -> 124 (huitzil's own number; site 0x5e542)
code_file 0x4286d0 +0x100  donovan x06965e (from vsav2 0x06965E)
code   0x46ab80 ILLEGAL  TRIPWIRE for unresolved 0x22f2d2
# x06cac0+0x546: unresolved 0x22f2d2 -> tripwire 0x46ab80
code   0x46ab90 ILLEGAL  TRIPWIRE for unresolved 0x4cb0
# x06cac0+0x552: unresolved 0x4cb0 -> tripwire 0x46ab90
code   0x46aba0 ILLEGAL  TRIPWIRE for unresolved 0x4c96
# x06cac0+0x586: unresolved 0x4c96 -> tripwire 0x46aba0
# x06cac0+0x58e: unresolved 0x22f2d2 -> tripwire 0x46ab80
# bank_ref 0xd7118 -> 0xbcf7a (delta rule, known table base)
# bank_ref 0xd7118 -> 0xbcf7a (delta rule, known table base)
code   0x46abb0 ILLEGAL  TRIPWIRE for unresolved 0x3a90
# x06cac0+0xacc: unresolved 0x3a90 -> tripwire 0x46abb0
code   0x46abc0 ILLEGAL  TRIPWIRE for unresolved 0x3a76
# x06cac0+0xb18: unresolved 0x3a76 -> tripwire 0x46abc0
# x06cac0+0xb60: unresolved 0x3a76 -> tripwire 0x46abc0
# x06cac0+0xbac: unresolved 0x3a76 -> tripwire 0x46abc0
# pcrel_escape_fix x06cac0: 0 escapes -> 0 trampolines (0 tripwired), pad 0xebc..0xf1c
code_file 0x4287d0 +0xca8  donovan x06cac0 code (from vsav2 0x06CAC0)
data_file 0x429478 +0x274  donovan x06cac0 RAW TABLES (unencrypted; vs2 0x06D768)
code   0x46abd0 ILLEGAL  TRIPWIRE for unresolved 0x281696
# x088512+0x348: unresolved 0x281696 -> tripwire 0x46abd0
code   0x46abe0 ILLEGAL  TRIPWIRE for unresolved 0x289b14
# x088512+0x126a: unresolved 0x289b14 -> tripwire 0x46abe0
# x088512+0x127c: unresolved 0x289b14 -> tripwire 0x46abe0
code   0x46abf0 ILLEGAL  TRIPWIRE for unresolved 0x28ed08
# x088512+0x1de2: unresolved 0x28ed08 -> tripwire 0x46abf0
code   0x46ac00 ILLEGAL  TRIPWIRE for unresolved 0x36784a
# x088512+0x1dee: unresolved 0x36784a -> tripwire 0x46ac00
code   0x46ac10 sound stub for 0x50ee (vsavj sfx id 0x7e)
code   0x46ac30 sound stub for 0x50a0 (vsavj sfx id 0x7b)
code   0x46ac50 sound stub for 0x50d4 (vsavj sfx id 0x7d)
code   0x46ac70 sound stub for 0x50ba (vsavj sfx id 0x7c)
code   0x46ac90 sound stub for 0x4e2a (vsavj sfx id 0x8f)
code   0x46acb0 sound stub for 0x4df6 (vsavj sfx id 0x86)
code   0x46acd0 ILLEGAL  TRIPWIRE for unresolved 0x2695d0
# x088512+0x2894: unresolved 0x2695d0 -> tripwire 0x46acd0
code   0x46ace0 ILLEGAL  TRIPWIRE for unresolved 0x2abd58
# x088512+0x359c: unresolved 0x2abd58 -> tripwire 0x46ace0
# x088512+0x22c: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x088512+0x1814: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x088512+0x2bee: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x088512+0x2be6: port_patch 000e -> 000c (companion queue class 7 (vs2-only) -> vsavj class 6 (the Anita precedent))
# x088512+0x2d12: port_patch 3d7c20000018 -> 3d7c30000018 (companion-piece bank setter: effect page bank 1 -> WIDE bank 5 (native codes))
# x088512+0x3a02: port_patch 397c20000018 -> 397c30000018 (companion-piece bank setter: effect page bank 1 -> WIDE bank 5 (native codes))
# x088512+0x3a40: port_patch 397c20000018 -> 397c30000018 (companion-piece bank setter: effect page bank 1 -> WIDE bank 5 (native codes))
# x088512+0x20b0: type_renumber stamp_l_ind type 116 -> 128 (huitzil's own number; site 0x5e542)
# x088512+0x27ce: type_renumber stamp_l_ind type 117 -> 130 (huitzil's own number; site 0x5e542)
# x088512+0x1dc4: type_renumber stamp_l_ind type 119 -> 134 (huitzil's own number; site 0x5e542)
# x088512+0x2138: type_renumber stamp_l_ind type 119 -> 134 (huitzil's own number; site 0x5e542)
code   0x46acf0 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_l_ind 28bc01014102, rts)
# x088512+0x2ebc: owner_tag stamp_l_ind type 65 -> jsr 0x46acf0 (huitzil id 0x10)
code   0x46ad00 owner-tag thunk (huitzil id 0x10 -> (+0x7f,A4), then stamp_l_ind 28bc01014100, rts)
# x088512+0x2f54: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x3034: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x305e: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x3088: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x30b2: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x30dc: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x3106: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x3130: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x329a: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x32c4: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x32ee: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x3318: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x3342: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x336c: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x3396: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x33c0: owner_tag stamp_l_ind type 65 -> jsr 0x46ad00 (huitzil id 0x10)
# x088512+0x3ae4: data_in_code reroute -> helper 0x46ae10, table 0x46ad10 (DATA view of vsav2 0x08c042; pod-zone word offset/record table (a3 re-derived from it; self-relative))
code_file 0x4296f0 +0x3b78  donovan x088512 code (from vsav2 0x088512)
data_file 0x42d268 +0x20  donovan x088512 RAW TABLES (unencrypted; vs2 0x08C08A)
code_file 0x42d290 +0x100  donovan x0926e4 (from vsav2 0x0926E4)
code_file 0x42d390 +0x306  donovan x093460 (from vsav2 0x093460)
data_file 0x45dce0 +0x900  donovan x0d143e (from vsav2 0x0D143E)
data_file 0x45e5e0 +0xe3c  donovan x100000 (from vsav2 0x100000)
code   0x46ae20 ILLEGAL  TRIPWIRE for unresolved 0x2c31aa
# x2b7ef4+0xb0d9: unresolved 0x2c31aa -> tripwire 0x46ae20
code   0x46ae30 ILLEGAL  TRIPWIRE for unresolved 0x2c31e4
# x2b7ef4+0xb0fd: unresolved 0x2c31e4 -> tripwire 0x46ae30
code   0x46ae40 ILLEGAL  TRIPWIRE for unresolved 0x2c3236
# x2b7ef4+0xb105: unresolved 0x2c3236 -> tripwire 0x46ae40
code   0x46ae50 ILLEGAL  TRIPWIRE for unresolved 0x2c325c
# x2b7ef4+0xb10d: unresolved 0x2c325c -> tripwire 0x46ae50
code   0x46ae60 ILLEGAL  TRIPWIRE for unresolved 0x2c3272
# x2b7ef4+0xb115: unresolved 0x2c3272 -> tripwire 0x46ae60
code   0x46ae70 ILLEGAL  TRIPWIRE for unresolved 0x2c3280
# x2b7ef4+0xb11d: unresolved 0x2c3280 -> tripwire 0x46ae70
code   0x46ae80 ILLEGAL  TRIPWIRE for unresolved 0x2c3296
# x2b7ef4+0xb125: unresolved 0x2c3296 -> tripwire 0x46ae80
code   0x46ae90 ILLEGAL  TRIPWIRE for unresolved 0x2c32a4
# x2b7ef4+0xb12d: unresolved 0x2c32a4 -> tripwire 0x46ae90
code   0x46aea0 ILLEGAL  TRIPWIRE for unresolved 0x2c32b2
# x2b7ef4+0xb135: unresolved 0x2c32b2 -> tripwire 0x46aea0
# x2b7ef4: effect-c5 — 5714 bank-1 codes kept NATIVE (art -> group C bank 5); 114 coord lists matched, 617 ported (11336B fragment)
data_file 0x45f420 +0xb20c  donovan x2b7ef4 (from vsav2 0x2B7EF4)
data     0x46db00 +0x500  sprite palette block (vsav2 0x39BC9C); poke32 0x38c1d8 (table 0x38c198 row 0x10)
data     0x46e000 +0xdc0  effect palette block (vsav2 0x3AB69C); poke32 0x38c258 (table 0x38c218 row 0x10)
poke32 0x0bceba <- 0x0042d6a0  anim_index_a[0x10] donovan anim
poke32 0x0bcf3a <- 0x004321fc  anim_index_a2[0x10] donovan anim
poke32 0x0bcfba <- 0x0042fd0a  anim_index_b[0x10] donovan anim
poke32 0x0bd03a <- 0x0042fc94  anim_index_c[0x10] donovan anim
poke32 0x0bd0ba <- 0x00437d04  anim_index_proj[0x10] donovan anim
data   0x0bd8fa +0x8  param32_a[0x10] value
data   0x0bde7a +0x30  jump_params[0x10] value
poke32 0x0bd9ba <- 0x0045a770  hitbox_base[0x10] donovan hitbox
poke32 0x0bda3a <- 0x0045a650  hitbox_comp[0x10] donovan hitbox
poke32 0x0bdaba <- 0x0045d944  proj_hitbox_base[0x10] donovan hitbox_proj
poke32 0x0bdb3a <- 0x0045d910  proj_hitbox_comp[0x10] donovan hitbox_proj
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
poke32 0x0bf2da <- 0x00414928  tail_code_ptr[0x10] donovan code
# tail_data_ptr: ptr row owned by sound_table hui_sfx_records — generic repoint suppressed (14z-65 sound_table / 14z-130 data_port)
poke32 0x0bf05a <- 0x0045e5e0  ai_script_0[0x10] donovan x100000
poke32 0x0bf0da <- 0x0045e6c0  ai_script_1[0x10] donovan x100000
poke32 0x0bf15a <- 0x0045eeec  ai_script_2[0x10] donovan x100000
poke32 0x0bf1da <- 0x0045f406  ai_script_3[0x10] donovan x100000
poke32 0x0bd4ba <- 0x00024ea4  dispatch_07[0x10] engine twin of 0x23afe (alias char row 0x2d68e differs)
poke32 0x0bd1ba <- 0x0041414c  dispatch_01[0x10] donovan handler
poke32 0x0bd23a <- 0x00414a10  dispatch_02[0x10] donovan handler
poke32 0x0bd2ba <- 0x00414a10  dispatch_03[0x10] donovan handler
poke32 0x0bd33a <- 0x00414a10  dispatch_04[0x10] donovan handler
poke32 0x0bd3ba <- 0x00416234  dispatch_05[0x10] donovan handler
poke32 0x0bd43a <- 0x00414366  dispatch_06[0x10] donovan handler
poke32 0x0bd53a <- 0x00414592  dispatch_08[0x10] donovan handler
poke32 0x0bd5ba <- 0x004146de  dispatch_09[0x10] donovan handler
poke32 0x0bd63a <- 0x004142f2  dispatch_10[0x10] donovan handler
poke32 0x0bd6ba <- 0x00416684  dispatch_11[0x10] donovan handler
poke32 0x0bd73a <- 0x004168a0  dispatch_12[0x10] donovan handler
poke32 0x0bd7ba <- 0x004168d0  dispatch_13[0x10] donovan handler
poke32 0x0bd83a <- 0x004164d0  dispatch_14[0x10] donovan handler
poke32 0x0bf25a <- 0x004145b6  dispatch_15[0x10] donovan handler
poke32 0x0bf35a <- 0x0041612a  dispatch_16[0x10] donovan handler
poke32 0x0bf3da <- 0x00416218  dispatch_17[0x10] donovan handler
poke32 0x0bf4da <- 0x0041693a  dispatch_18[0x10] donovan handler
poke32 0x0bf65a <- 0x00416220  dispatch_19[0x10] donovan handler
poke16 0x0898a4 <- 0x869a  aux hud_mug_entry_10
poke32 0x089944 <- 0x86920102  aux hud_name_entry_10_hi
poke32 0x089948 <- 0xffe80002  aux hud_name_entry_10_lo
poke16 0x028d4e <- 0xf1b  aux effect_map_4e4f
poke16 0x028d50 <- 0x1f19  aux effect_map_5051
poke16 0x028d52 <- 0xf03  aux effect_map_5253
data   0x46edc0 +0x1d80  data_port grab_hold_keyframes PLACED (tenant at 0x10; host block 0x92c4a untouched) <- vsav2 0x0c56aa (0 fixes)
poke32 0x0be2ba <- 0x46edc0  data_port grab_hold_keyframes ptr-table 0xbe27a row 0x10
data   0x00b668 +0x40  data_port voice_borrow_candidates_a <- vsav2 0x009f2a (0 fixes)
data   0x00bf68 +0x40  data_port voice_borrow_voicenums_b <- vsav2 0x00a82a (4 fixes)
data   0x470b40 +0xc0  sound_table hui_sfx_records <- vsav2 0x0c742a (24 entries; kept ['0x110@1', '0x111@2', '0x112@3', '0x08d@5', '0x07f@6', '0x080@7', '0x081@8', '0x082@9', '0x0d8@10', '0x199@11', '0x083@12', '0x088@13', '0x089@14', '0x08a@15', '0x08b@16', '0x08c@17', '0x08e@18', '0x096@19', '0x094@20', '0x199@21', '0x198@22']; zeroed 2 unplayable ids; remapped [(5, '0x745', '0x8d'), (6, '0x735', '0x7f'), (7, '0x736', '0x80'), (8, '0x737', '0x81'), (9, '0x738', '0x82'), (10, '0x739', '0xd8'), (11, '0x73a', '0x199'), (12, '0x73b', '0x83'), (13, '0x740', '0x88'), (14, '0x741', '0x89'), (15, '0x742', '0x8a'), (16, '0x743', '0x8b'), (17, '0x744', '0x8c'), (18, '0x746', '0x8e'), (19, '0x74e', '0x96'), (20, '0x74c', '0x94')])
poke32 0x0bf45a <- 0x470b40  sound_table hui_sfx_records per-char ptr row 0x10 (was 0x938ba)
data   0x470c00 +0x1c  select_records portrait/p1 coord list (7 pairs, vs2 0x303238)
data   0x470c20 +0x26  select_records portrait/p1 record (vs2 0x2a5e4a, 7 entries, budget 0x5b = vs2's own)
poke32 0x26746a <- 0x470c20  select_records portrait/p1 array row 0x10 (was 0x271924, the base-half alias)
data   0x470c50 +0x1c  select_records portrait/p2 coord list (7 pairs, vs2 0x3035a8)
data   0x470c70 +0x26  select_records portrait/p2 record (vs2 0x2a625a, 7 entries, budget 0x5b = vs2's own)
poke32 0x2674ea <- 0x470c70  select_records portrait/p2 array row 0x10 (was 0x271d36, the base-half alias)
data   0x470ca0 +0x4  select_records name_banner/p1 coord list (1 pairs, vs2 0x303730)
data   0x470cb0 +0xe  select_records name_banner/p1 record (vs2 0x2a64d6, 1 entries, budget 0x8 = vs2's own)
poke32 0x2675ea <- 0x470cb0  select_records name_banner/p1 array row 0x10 (was 0x272148, the base-half alias)
data   0x470cc0 +0x8  select_records name_banner/p2 coord list (2 pairs, vs2 0x303d9c)
data   0x470cd0 +0x12  select_records name_banner/p2 record (vs2 0x2a7506, 2 entries, budget 0x3 = vs2's own)
poke32 0x26766a <- 0x470cd0  select_records name_banner/p2 array row 0x10 (was 0x273052, the base-half alias)
data   0x470cf0 +0x14  select_records splash_p1/p1 coord list (5 pairs, vs2 0x304028)
data   0x470d10 +0x1e  select_records splash_p1/p1 record (vs2 0x2a7b06, 5 entries, budget 0x4c = vs2's own)
poke32 0x2672ea <- 0x470d10  select_records splash_p1/p1 array row 0x10 (was 0x273462, the base-half alias)
data   0x470d30 +0x14  select_records splash_p2/p1 coord list (5 pairs, vs2 0x3042b8)
data   0x470d50 +0x1e  select_records splash_p2/p1 record (vs2 0x2a7e36, 5 entries, budget 0x4c = vs2's own)
poke32 0x26736a <- 0x470d50  select_records splash_p2/p1 array row 0x10 (was 0x2737a8, the base-half alias)
data   0x470d70 +0x84  select_records win_quote/p1 coord list (33 pairs, vs2 0x304bd8)
data   0x470e00 +0x8e  select_records win_quote/p1 record (vs2 0x2a881e, 33 entries, budget 0x8a = vs2's own)
poke32 0x2673ea <- 0x470e00  select_records win_quote/p1 array row 0x10 (was 0x273aee, the base-half alias)
poke32 0x268a42 <- 0x2724a2  select_records highlight/p1 array row 0x10 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x272554)
poke32 0x268ac2 <- 0x2726ce  select_records highlight/p2 array row 0x10 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x272780)
# select_records: 0 bank-1 tile placements -> select_tiles.json (only the composed records' art; the slot-0x0F splash/win-quote families are NOT placed, so that Jedah art stays vanilla)
# select_records: 236 native bank-1 tiles -> select_bank5.json (copied vs2 -> group C bank 5 by build_gfx; the drawer's bank is thunk-gated per hover)
# site_thunk name_bank_variant_id: body deferred to the 0x05fce0 chain (30 bytes)
# site_thunk splash_bank_variant_id: body deferred to the 0x06c0e0 chain (30 bytes)
# site_thunk winquote_bank_variant_id: body deferred to the 0x05f328 chain (22 bytes)
code   0x470e90 +0x1a  site_thunk tenant_jump_seq; site 0x022a0e jmp-routed
code   0x470eb0 +0xe  site_thunk shadow_seq_guard; site 0x08245c jmp-routed
data   0x470ec0 +0x140  site_thunk select_pal_variant_id data block <- vsav2 0x3c12dc
# site_thunk select_pal_variant_id: body deferred to the 0x05f146 chain (56 bytes)
data   0x471000 +0x54  site_thunk throw_arc_tables data block <- vsav2 0x0279b4
data   0x471060 +0x370  site_thunk throw_arc_tables data block <- vsav2 0x027a08
code   0x4713d0 +0x42  site_thunk throw_arc_tables; site 0x028386 jmp-routed
code   0x471420 +0xe  site_thunk idmask_victim_spawn; site 0x060ef0 jmp-routed
code   0x471430 +0x10  site_thunk idmask_piece_subtype; site 0x05e7d6 jmp-routed
data   0x471440 +0x100  site_thunk df_gold_variant_id data block <- vsav2 0x3abedc
code   0x471540 +0x54  site_thunk df_gold_variant_id; site 0x02a8d6 jmp-routed
code   0x4715a0 +0xfe  site_thunk beam_list_type6; site 0x01b6aa jmp-routed
code   0x4716a0 +0x1d6  site_thunk index_window_018468; site 0x018460 jmp-routed
code   0x0282f4 +0x2  code_word obj_bank_word_slot (slot entry -> 1000)
code   0x05f240 +0x2  code_word win_pos_x_slot (slot entry -> 00c0)
code   0x05f242 +0x2  code_word win_pos_y_slot (slot entry -> 0080)
code   0x02a8c4 +0x2  code_word df_seq_entry_10 (slot entry -> 0032)
code   0x003bee +0x2  code_word hui_kernel_voice_e0 (01d0 -> 01a2)
code   0x003c5a +0x2  code_word hui_kernel_voice_e1 (01d1 -> 02a1)
code   0x003cc6 +0x2  code_word hui_kernel_voice_e2 (01d2 -> 02a2)
code   0x003d30 +0x2  code_word hui_kernel_voice_e3 (01d3 -> 01c1)
code   0x080aec +0x4  code_ptr beam_effect_class16 (00080b44 -> 0042d390 = x093460+0x0)
code   0x080b28 +0x4  code_ptr beam_effect_class31 (00080b44 -> 0042d290 = x0926e4+0x0)
# stage 1: Jedah hitbox block 0x093AAA+0x0 (base 0x93b6a comp 0x93aaa)
# table_fix: region x026142 len 0x1400 -> 0x1440 (merged vanilla bank table; tenant rows written per tenant)
data_file 0x485740 +0x1b500  donovan anim (from vsav2 0x264086)
data_file 0x4a0c40 +0x190  donovan aux0_0 (from vsav2 0x334170)
data_file 0x4a0dd0 +0x190  donovan aux0_1 (from vsav2 0x33CD00)
data_file 0x4a0f60 +0xd830  donovan aux0_2 (from vsav2 0x344A60)
code   0x4bc940 farm-port stub for 0x2916c (param at 0x4bc920, common 0x29f4a)
code   0x4bc960 farm-port stub for 0x2915c (param at 0x4bc950, common 0x29f4a)
code   0x4bc980 farm-port stub for 0x29164 (param at 0x4bc970, common 0x29f4a)
code   0x4bc9a0 farm-port stub for 0x29184 (param at 0x4bc990, common 0x29f4a)
code   0x4bc9c0 farm-port stub for 0x2918c (param at 0x4bc9b0, common 0x29f4a)
code   0x4bc9d0 sound stub for 0x4f96 (vsavj sfx id 0xa1)
code   0x4bc9f0 slot-clearing alloc wrapper for 0x15702 -> 0x16fba (0x80 cleared, +8 preserved)
code   0x4bca20 slot-clearing alloc wrapper for 0x1572e -> 0x16fe6 (0x80 cleared, +8 preserved)
code   0x4bca50 ILLEGAL  TRIPWIRE for unresolved 0x4223c
# code+0x3ad8: unresolved 0x4223c -> tripwire 0x4bca50
code   0x4bca60 ILLEGAL  TRIPWIRE for unresolved 0x42cee
# code+0x41b0: unresolved 0x42cee -> tripwire 0x4bca60
code   0x4bca70 ILLEGAL  TRIPWIRE for unresolved 0x448d4
# code+0x5062: unresolved 0x448d4 -> tripwire 0x4bca70
# code+0x1ecc: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (P own code zone): vs2 bank 3 -> WIDE bank 4)
# code+0x23fe: type_renumber stamp_l_ind type 114 -> 125 (pyron's own number; site 0x5e542)
# code+0x2b14: type_renumber stamp_l_ind type 114 -> 125 (pyron's own number; site 0x5e542)
# code+0x2b86: type_renumber stamp_l_ind type 114 -> 125 (pyron's own number; site 0x5e542)
# code+0x2b9c: type_renumber stamp_l_ind type 114 -> 125 (pyron's own number; site 0x5e542)
# code+0x2cae: type_renumber stamp_l_ind type 114 -> 125 (pyron's own number; site 0x5e542)
# code+0x2d84: type_renumber stamp_l_ind type 114 -> 125 (pyron's own number; site 0x5e542)
# code+0x2f66: type_renumber stamp_l_ind type 114 -> 125 (pyron's own number; site 0x5e542)
# code+0x370a: type_renumber stamp_l_ind type 114 -> 125 (pyron's own number; site 0x5e542)
# code+0x3852: type_renumber stamp_l_ind type 114 -> 125 (pyron's own number; site 0x5e542)
# code+0x387e: type_renumber stamp_l_ind type 114 -> 125 (pyron's own number; site 0x5e542)
# code+0x3a5c: type_renumber stamp_l_ind type 114 -> 125 (pyron's own number; site 0x5e542)
# code+0x1ec0: type_renumber stamp_b_d16 type 115 -> 127 (pyron's own number; site 0x5e542)
# code+0x1faa: type_renumber stamp_l_ind type 118 -> 133 (pyron's own number; site 0x5e542)
code   0x4bca80 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_b_d16 197c00400002, rts)
# code+0x892: owner_tag stamp_b_d16 type 64 -> jsr 0x4bca80 (pyron id 0x11)
code   0x4bca90 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_b_d16 197c00410002, rts)
# code+0x9ba: owner_tag stamp_b_d16 type 65 -> jsr 0x4bca90 (pyron id 0x11)
code   0x4bcaa0 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_b_d16 197c00420002, rts)
# code+0x1464: owner_tag stamp_b_d16 type 66 -> jsr 0x4bcaa0 (pyron id 0x11)
code   0x4bcab0 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_b_d16 197c00430002, rts)
# code+0x188c: owner_tag stamp_b_d16 type 67 -> jsr 0x4bcab0 (pyron id 0x11)
code   0x4bcac0 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_b_d16 197c003e0002, rts)
# code+0x295a: owner_tag stamp_b_d16 type 62 -> jsr 0x4bcac0 (pyron id 0x11)
code   0x4bcad0 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_b_d16 197c003f0002, rts)
# code+0x2ae0: owner_tag stamp_b_d16 type 63 -> jsr 0x4bcad0 (pyron id 0x11)
code   0x4bcae0 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_b_d16 197c004b0002, rts)
# code+0x2aec: owner_tag stamp_b_d16 type 75 -> jsr 0x4bcae0 (pyron id 0x11)
code   0x4bcaf0 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_b_d16 197c003d0002, rts)
# code+0x3994: owner_tag stamp_b_d16 type 61 -> jsr 0x4bcaf0 (pyron id 0x11)
code   0x4bcb00 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_b_d16 197c00490002, rts)
# code+0x45ba: owner_tag stamp_b_d16 type 73 -> jsr 0x4bcb00 (pyron id 0x11)
code   0x4bcb10 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_l_ind 28bc01014200, rts)
# code+0x4ca8: owner_tag stamp_l_ind type 66 -> jsr 0x4bcb10 (pyron id 0x11)
code   0x4bcb20 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_l_ind 28bc01004202, rts)
# code+0x4d72: owner_tag stamp_l_ind type 66 -> jsr 0x4bcb20 (pyron id 0x11)
# code+0x1ee: data_in_code [pointer-inline] lea.l #0x4bcb30,a2 in place (DATA view of vsav2 0x0576f4; air-dive per-strength (xv,yv) rows; a2 re-derived by `lea (a2,d2.w),a2`)
code_file 0x471880 +0x5200  donovan code (from vsav2 0x0574C0)
data_file 0x4ae790 +0x16b6  donovan hitbox (from vsav2 0x0C7502)
# hitbox_proj+0x2f8: port_patch 0151 -> 014f (Cosmo Disruption sub-state 81 -> 79: vsavj's dispatch table has 80 entries, so 81 read past its end into the next dispatcher's operand and jumped into the table (watchdog reset). 79's entry is already 0x0224 = the same handler vs2 uses.)
data_file 0x4afe50 +0x322  donovan hitbox_proj (from vsav2 0x0D0986)
# x026142+0x1414: bank table row 0x13 <- 0x1000 (bank 4, WIDE encoding; vanilla row was 0x2000) — tenant-driven
# x026142+0x140e: bank table row 0x10 <- 0x1000 (bank 4, WIDE encoding; vanilla row was 0x6000) — tenant-driven
# x026142+0x1410: bank table row 0x11 <- 0x1000 (bank 4, WIDE encoding; vanilla row was 0x6000) — tenant-driven
# x026142+0x13ee: table_fix 48 bytes (merged vanilla bank table; tenant rows written per tenant)
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
# pcrel_escape_fix x026142: 9 escapes -> 6 trampolines (0 tripwired), pad 0x1440..0x14a0
code_file 0x476a80 +0x14a0  donovan x026142 (from vsav2 0x026142)
# bank_ref 0xd6ebe -> 0xbcd20 (delta rule, 16B byte-identical)
# bank_ref 0xd699e -> 0xbc800 (delta rule, 16B byte-identical)
# bank_ref 0xd671e -> 0xbc580 (delta rule, 16B byte-identical)
# bank_ref 0xd671e -> 0xbc580 (delta rule, 16B byte-identical)
# bank_ref 0xd679e -> 0xbc600 (delta rule, 16B byte-identical)
# bank_ref 0xd679e -> 0xbc600 (delta rule, 16B byte-identical)
# x028122+0x9a0: port_patch 3b7c0001b498 -> 3b7c0001b446 (obj-hit dmg: flag var -> vsavj layout (-0x4BBA))
# x028122+0x9a6: port_patch 426db494 -> 426db442 (obj-hit dmg: clr damage var -> vsavj layout (-0x4BBE))
# x028122+0x9b6: port_patch 3b42b494 -> 3b42b442 (obj-hit dmg: scaled damage -> vsavj layout (-0x4BBE))
# x028122+0x9ba: port_patch 3b7c0000b498 -> 3b7c0000b446 (obj-hit dmg: flag clear -> vsavj layout (-0x4BBA))
# x028122+0x9c0: port_patch 426db496 -> 426db444 (obj-hit dmg: clr white var -> vsavj layout (-0x4BBC))
# x028122+0x9d0: port_patch 3b42b496 -> 3b42b444 (obj-hit dmg: white damage -> vsavj layout (-0x4BBC))
code_file 0x477f20 +0xe00  donovan x028122 (from vsav2 0x028122)
code   0x4bcb40 ILLEGAL  TRIPWIRE for unresolved 0x12f484
# x05c800+0x152a: unresolved 0x12f484 -> tripwire 0x4bcb40
# x05c800+0x16a4: unresolved 0x12f484 -> tripwire 0x4bcb40
code   0x4bcb50 ILLEGAL  TRIPWIRE for unresolved 0x167bf4
# x05c800+0x2622: unresolved 0x167bf4 -> tripwire 0x4bcb50
# x05c800+0x2a20: unresolved 0x167bf4 -> tripwire 0x4bcb50
code   0x4bcb60 ILLEGAL  TRIPWIRE for unresolved 0x17f176
# x05c800+0x2ae4: unresolved 0x17f176 -> tripwire 0x4bcb60
# x05c800+0x3034: unresolved 0x17f176 -> tripwire 0x4bcb60
code   0x4bcb70 ILLEGAL  TRIPWIRE for unresolved 0x181592
# x05c800+0x3072: unresolved 0x181592 -> tripwire 0x4bcb70
# x05c800+0x738: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 (Jedah band) / WIDE bank 4)
# x05c800+0x58d4: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (a4 form): vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x05c800+0x5994: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (a4 form): vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
code   0x4bcb80 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_l_ind 28bc01003b22, rts)
# x05c800+0x83a: owner_tag stamp_l_ind type 59 -> jsr 0x4bcb80 (pyron id 0x11)
# pcrel_escape_fix x05c800: 2 escapes -> 1 trampolines (0 tripwired), pad 0x6a00..0x6a20
code_file 0x478d20 +0x6a20  donovan x05c800 (from vsav2 0x05C800)
code_file 0x47f740 +0x280  donovan x0672d0 (from vsav2 0x0672D0)
code_file 0x47f9c0 +0x2f6  donovan x067550 (from vsav2 0x067550)
code   0x4bcb90 sound stub for 0x4fb0 (vsavj sfx id 0xa0)
code   0x4bcbb0 sound stub for 0x4fca (vsavj sfx id 0xa5)
code_file 0x47fcc0 +0x1ba  donovan x067846 (from vsav2 0x067846)
code_file 0x47fe80 +0x60c  donovan x067a00 (from vsav2 0x067A00)
# x06800c+0x354: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x396: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x3de: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x422: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x348: type_renumber stamp_b_d16 type 115 -> 127 (pyron's own number; site 0x5e542)
# x06800c+0x38a: type_renumber stamp_b_d16 type 115 -> 127 (pyron's own number; site 0x5e542)
# x06800c+0x3d2: type_renumber stamp_b_d16 type 115 -> 127 (pyron's own number; site 0x5e542)
# x06800c+0x416: type_renumber stamp_b_d16 type 115 -> 127 (pyron's own number; site 0x5e542)
code_file 0x480490 +0x44c  donovan x06800c (from vsav2 0x06800C)
code_file 0x4808e0 +0x310  donovan x068458 (from vsav2 0x068458)
code_file 0x480bf0 +0x264  donovan x068768 (from vsav2 0x068768)
code   0x4bcbd0 sound stub for 0x4efa (vsavj sfx id 0x90)
code_file 0x480e60 +0x2ac  donovan x0689cc (from vsav2 0x0689CC)
code   0x4bcbf0 +0x40  patched clone of 0x5459a for vs2 0x5c77e (unmasked set-anim entry; false byte-matc)
code   0x4bcc30 sound stub for 0x4f62 (vsavj sfx id 0x7f)
code_file 0x481110 +0x3ce  donovan x068c78 (from vsav2 0x068C78)
# x069046+0x260: type_renumber stamp_l_ind type 114 -> 125 (pyron's own number; site 0x5e542)
code   0x4bcc50 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_l_ind 28bc01004206, rts)
# x069046+0x4a: owner_tag stamp_l_ind type 66 -> jsr 0x4bcc50 (pyron id 0x11)
code   0x4bcc60 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_l_ind 28bc01004204, rts)
# x069046+0x130: owner_tag stamp_l_ind type 66 -> jsr 0x4bcc60 (pyron id 0x11)
code_file 0x4814e0 +0x2b0  donovan x069046 (from vsav2 0x069046)
# x0692f6+0x19a: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x0692f6+0x18e: type_renumber stamp_b_d16 type 115 -> 127 (pyron's own number; site 0x5e542)
code_file 0x481790 +0x368  donovan x0692f6 (from vsav2 0x0692F6)
# x06965e+0xac: type_renumber stamp_l_ind type 114 -> 125 (pyron's own number; site 0x5e542)
code_file 0x481b00 +0x100  donovan x06965e (from vsav2 0x06965E)
code   0x4bcc70 ILLEGAL  TRIPWIRE for unresolved 0x281696
# x088512+0x348: unresolved 0x281696 -> tripwire 0x4bcc70
code   0x4bcc80 ILLEGAL  TRIPWIRE for unresolved 0x289b14
# x088512+0x126a: unresolved 0x289b14 -> tripwire 0x4bcc80
# x088512+0x127c: unresolved 0x289b14 -> tripwire 0x4bcc80
code   0x4bcc90 ILLEGAL  TRIPWIRE for unresolved 0x24edd4
# x088512+0x1362: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x13a0: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x13e4: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x1428: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x1464: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x14a2: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x150a: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x154e: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x1590: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x15f0: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x1670: unresolved 0x24edd4 -> tripwire 0x4bcc90
code   0x4bcca0 ILLEGAL  TRIPWIRE for unresolved 0x24a3ce
# x088512+0x16d8: unresolved 0x24a3ce -> tripwire 0x4bcca0
# x088512+0x1732: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x1796: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x17fa: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x18ee: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x191c: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x194a: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x1994: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x1cd2: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x1d1a: unresolved 0x24edd4 -> tripwire 0x4bcc90
code   0x4bccb0 ILLEGAL  TRIPWIRE for unresolved 0x28ed08
# x088512+0x1de2: unresolved 0x28ed08 -> tripwire 0x4bccb0
code   0x4bccc0 ILLEGAL  TRIPWIRE for unresolved 0x36784a
# x088512+0x1dee: unresolved 0x36784a -> tripwire 0x4bccc0
code   0x4bccd0 sound stub for 0x50ee (vsavj sfx id 0x7e)
code   0x4bccf0 sound stub for 0x50a0 (vsavj sfx id 0x7b)
code   0x4bcd10 sound stub for 0x50d4 (vsavj sfx id 0x7d)
code   0x4bcd30 sound stub for 0x50ba (vsavj sfx id 0x7c)
code   0x4bcd50 ILLEGAL  TRIPWIRE for unresolved 0x25111e
# x088512+0x2156: unresolved 0x25111e -> tripwire 0x4bcd50
# x088512+0x21d2: unresolved 0x25111e -> tripwire 0x4bcd50
# x088512+0x26e2: unresolved 0x25111e -> tripwire 0x4bcd50
code   0x4bcd60 sound stub for 0x4e2a (vsavj sfx id 0x8f)
code   0x4bcd80 sound stub for 0x4df6 (vsavj sfx id 0x86)
# x088512+0x28ce: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x290c: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x294a: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x2986: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x29c4: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x2a2c: unresolved 0x24edd4 -> tripwire 0x4bcc90
# x088512+0x2a6a: unresolved 0x24edd4 -> tripwire 0x4bcc90
code   0x4bcda0 ILLEGAL  TRIPWIRE for unresolved 0x2abd58
# x088512+0x359c: unresolved 0x2abd58 -> tripwire 0x4bcda0
# x088512+0x22c: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x088512+0x1814: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x088512+0x2bee: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter: vs2 bank 3 -> vsav bank 2 / WIDE bank 4)
# x088512+0x2be6: port_patch 000e -> 000c (companion queue class 7 (vs2-only) -> vsavj class 6 (the Anita/H precedent))
# x088512+0x20b0: type_renumber stamp_l_ind type 116 -> 129 (pyron's own number; site 0x5e542)
# x088512+0x27ce: type_renumber stamp_l_ind type 117 -> 131 (pyron's own number; site 0x5e542)
# x088512+0x1dc4: type_renumber stamp_l_ind type 119 -> 135 (pyron's own number; site 0x5e542)
# x088512+0x2138: type_renumber stamp_l_ind type 119 -> 135 (pyron's own number; site 0x5e542)
code   0x4bcdb0 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_l_ind 28bc01014102, rts)
# x088512+0x2ebc: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdb0 (pyron id 0x11)
code   0x4bcdc0 owner-tag thunk (pyron id 0x11 -> (+0x7f,A4), then stamp_l_ind 28bc01014100, rts)
# x088512+0x2f54: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x3034: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x305e: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x3088: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x30b2: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x30dc: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x3106: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x3130: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x329a: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x32c4: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x32ee: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x3318: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x3342: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x336c: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x3396: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x33c0: owner_tag stamp_l_ind type 65 -> jsr 0x4bcdc0 (pyron id 0x11)
# x088512+0x3ae4: data_in_code reroute -> helper 0x4bced0, table 0x4bcdd0 (DATA view of vsav2 0x08c042; pod-zone word offset/record table (a3 re-derived from it; self-relative; shared-zone copy))
code_file 0x481c00 +0x3b40  donovan x088512 (from vsav2 0x088512)
data_file 0x4b0180 +0x900  donovan x0d143e (from vsav2 0x0D143E)
data_file 0x4b0a80 +0xc8e  donovan x100e3c (from vsav2 0x100E3C)
code   0x4bcee0 ILLEGAL  TRIPWIRE for unresolved 0x2c3136
# x2b7ef4+0xb0c9: unresolved 0x2c3136 -> tripwire 0x4bcee0
code   0x4bcef0 ILLEGAL  TRIPWIRE for unresolved 0x2c3170
# x2b7ef4+0xb0d1: unresolved 0x2c3170 -> tripwire 0x4bcef0
code   0x4bcf00 ILLEGAL  TRIPWIRE for unresolved 0x2c31aa
# x2b7ef4+0xb0d9: unresolved 0x2c31aa -> tripwire 0x4bcf00
code   0x4bcf10 ILLEGAL  TRIPWIRE for unresolved 0x2c31e4
# x2b7ef4+0xb0fd: unresolved 0x2c31e4 -> tripwire 0x4bcf10
code   0x4bcf20 ILLEGAL  TRIPWIRE for unresolved 0x2c3236
# x2b7ef4+0xb105: unresolved 0x2c3236 -> tripwire 0x4bcf20
code   0x4bcf30 ILLEGAL  TRIPWIRE for unresolved 0x2c325c
# x2b7ef4+0xb10d: unresolved 0x2c325c -> tripwire 0x4bcf30
code   0x4bcf40 ILLEGAL  TRIPWIRE for unresolved 0x2c3272
# x2b7ef4+0xb115: unresolved 0x2c3272 -> tripwire 0x4bcf40
code   0x4bcf50 ILLEGAL  TRIPWIRE for unresolved 0x2c3280
# x2b7ef4+0xb11d: unresolved 0x2c3280 -> tripwire 0x4bcf50
code   0x4bcf60 ILLEGAL  TRIPWIRE for unresolved 0x2c3296
# x2b7ef4+0xb125: unresolved 0x2c3296 -> tripwire 0x4bcf60
code   0x4bcf70 ILLEGAL  TRIPWIRE for unresolved 0x2c32a4
# x2b7ef4+0xb12d: unresolved 0x2c32a4 -> tripwire 0x4bcf70
code   0x4bcf80 ILLEGAL  TRIPWIRE for unresolved 0x2c32b2
# x2b7ef4+0xb135: unresolved 0x2c32b2 -> tripwire 0x4bcf80
# x2b7ef4: effect-c5 — 5714 bank-1 codes kept NATIVE (art -> group C bank 5); 114 coord lists matched, 617 ported (11336B fragment)
data_file 0x4b1710 +0xb20c  donovan x2b7ef4 (from vsav2 0x2B7EF4)
data     0x4bfbe0 +0x500  sprite palette block (vsav2 0x39C19C); poke32 0x38c1dc (table 0x38c198 row 0x11)
data     0x4c00e0 +0xdc0  effect palette block (vsav2 0x3AC45C); poke32 0x38c25c (table 0x38c218 row 0x11)
poke32 0x0bcebe <- 0x00485740  anim_index_a[0x11] donovan anim
poke32 0x0bcf3e <- 0x0048ac8a  anim_index_a2[0x11] donovan anim
poke32 0x0bcfbe <- 0x00487c0e  anim_index_b[0x11] donovan anim
poke32 0x0bd03e <- 0x0048768a  anim_index_c[0x11] donovan anim
poke32 0x0bd0be <- 0x0048ec6e  anim_index_proj[0x11] donovan anim
data   0x0bd902 +0x8  param32_a[0x11] value
data   0x0bdeaa +0x30  jump_params[0x11] value
poke32 0x0bd9be <- 0x004ae88c  hitbox_base[0x11] donovan hitbox
poke32 0x0bda3e <- 0x004ae790  hitbox_comp[0x11] donovan hitbox
poke32 0x0bdabe <- 0x004afe58  proj_hitbox_base[0x11] donovan hitbox_proj
poke32 0x0bdb3e <- 0x004afe50  proj_hitbox_comp[0x11] donovan hitbox_proj
data   0x0bdc02 +0x8  rec8_a[0x11] value
data   0x0be19c +0x2  word132[0x11] value
data   0x0be1dc +0x2  word_pos_a[0x11] value
data   0x0be21c +0x2  word_pos_b[0x11] value
data   0x0be382 +0x8  param32_b[0x11] value
data   0x0be482 +0x8  rec8_b[0x11] value
data   0x0be81c +0x2  word_y_off[0x11] value
data   0x0be85c +0x2  word_range[0x11] value
data   0x0be88a +0x2  byte15b[0x11] value
data   0x0bea98 +0x1e  byte2d_a[0x11] value
data   0x0bee58 +0x1e  byte2d_b[0x11] value
poke32 0x0bf2de <- 0x00471e72  tail_code_ptr[0x11] donovan code
# tail_data_ptr: ptr row owned by sound_table pyr_sfx_records — generic repoint suppressed (14z-65 sound_table / 14z-130 data_port)
poke32 0x0bf05e <- 0x004b0a80  ai_script_0[0x11] donovan x100e3c
poke32 0x0bf0de <- 0x004b0b6c  ai_script_1[0x11] donovan x100e3c
poke32 0x0bf15e <- 0x004b1458  ai_script_2[0x11] donovan x100e3c
poke32 0x0bf1de <- 0x004b16f8  ai_script_3[0x11] donovan x100e3c
poke32 0x0bd4be <- 0x00024ea4  dispatch_07[0x11] engine twin of 0x23afe (alias char row 0x30b9a differs)
code   0x4c0ea0 ILLEGAL  TRIPWIRE for unresolved 0x65c22
# obj_hook@0x54470 type 59 owner-dispatch fallback: unresolved 0x65c22 -> tripwire 0x4c0ea0
code   0x4c0eb0 obj_hook type 59 OWNER-DISPATCH (tag; donovan 0xcbe32; unknown owner -> tripwire 0x4c0ea0)
#   obj_hook@0x54470 type 59: stamp sites also exist in huitzil, pyron (no handler copy placed) — a live spawn there would tripwire under its OWN tag; solo builds already tripwire this type for them and playtest green (dead paths)
code   0x4c0ed0 ILLEGAL  TRIPWIRE for unresolved 0x65e5a
# obj_hook@0x54470 type 61 owner-dispatch fallback: unresolved 0x65e5a -> tripwire 0x4c0ed0
code   0x4c0ee0 obj_hook type 61 OWNER-DISPATCH (tag; donovan 0xcc06a; unknown owner -> tripwire 0x4c0ed0)
#   obj_hook@0x54470 type 61: stamp sites also exist in huitzil, pyron (no handler copy placed) — a live spawn there would tripwire under its OWN tag; solo builds already tripwire this type for them and playtest green (dead paths)
code   0x4c0f00 ILLEGAL  TRIPWIRE for unresolved 0x66ec4
# obj_hook@0x54470 type 62 owner-dispatch fallback: unresolved 0x66ec4 -> tripwire 0x4c0f00
code   0x4c0f10 obj_hook type 62 OWNER-DISPATCH (tag; donovan 0xcd0d4; unknown owner -> tripwire 0x4c0f00)
#   obj_hook@0x54470 type 62: stamp sites also exist in huitzil, pyron (no handler copy placed) — a live spawn there would tripwire under its OWN tag; solo builds already tripwire this type for them and playtest green (dead paths)
code   0x4c0f30 ILLEGAL  TRIPWIRE for unresolved 0x6717c
# obj_hook@0x54470 type 63 owner-dispatch fallback: unresolved 0x6717c -> tripwire 0x4c0f30
code   0x4c0f40 obj_hook type 63 OWNER-DISPATCH (tag; donovan 0xc28a0; unknown owner -> tripwire 0x4c0f30)
#   obj_hook@0x54470 type 63: stamp sites also exist in huitzil, pyron (no handler copy placed) — a live spawn there would tripwire under its OWN tag; solo builds already tripwire this type for them and playtest green (dead paths)
code   0x4c0f60 ILLEGAL  TRIPWIRE for unresolved 0x672d0
# obj_hook@0x54470 type 64 owner-dispatch fallback: unresolved 0x672d0 -> tripwire 0x4c0f60
code   0x4c0f70 obj_hook type 64 OWNER-DISPATCH (tag; huitzil 0x4264d0, pyron 0x47f740; unknown owner -> tripwire 0x4c0f60)
code   0x4c0fa0 ILLEGAL  TRIPWIRE for unresolved 0x67550
# obj_hook@0x54470 type 65 owner-dispatch fallback: unresolved 0x67550 -> tripwire 0x4c0fa0
code   0x4c0fb0 obj_hook type 65 OWNER-DISPATCH (tag; huitzil 0x426750, pyron 0x47f9c0; unknown owner -> tripwire 0x4c0fa0)
#   obj_hook@0x54470 type 65: stamp sites also exist in donovan (no handler copy placed) — a live spawn there would tripwire under its OWN tag; solo builds already tripwire this type for them and playtest green (dead paths)
code   0x4c0fe0 ILLEGAL  TRIPWIRE for unresolved 0x67846
# obj_hook@0x54470 type 66 owner-dispatch fallback: unresolved 0x67846 -> tripwire 0x4c0fe0
code   0x4c0ff0 obj_hook type 66 OWNER-DISPATCH (tag; huitzil 0x3ffd90, pyron 0x47fcc0; unknown owner -> tripwire 0x4c0fe0)
#   obj_hook@0x54470 type 66: stamp sites also exist in donovan (no handler copy placed) — a live spawn there would tripwire under its OWN tag; solo builds already tripwire this type for them and playtest green (dead paths)
code   0x4c1020 ILLEGAL  TRIPWIRE for unresolved 0x67a00
# obj_hook@0x54470 type 67 owner-dispatch fallback: unresolved 0x67a00 -> tripwire 0x4c1020
code   0x4c1030 obj_hook type 67 OWNER-DISPATCH (tag; huitzil 0x426a50, pyron 0x47fe80; unknown owner -> tripwire 0x4c1020)
code   0x4c1060 ILLEGAL  TRIPWIRE for unresolved 0x6800c
# obj_hook@0x54470 type 68 owner-dispatch fallback: unresolved 0x6800c -> tripwire 0x4c1060
code   0x4c1070 obj_hook type 68 OWNER-DISPATCH (tag; huitzil 0x427060, pyron 0x480490; unknown owner -> tripwire 0x4c1060)
code   0x4c10a0 ILLEGAL  TRIPWIRE for unresolved 0x68458
# obj_hook@0x54470 type 69 owner-dispatch fallback: unresolved 0x68458 -> tripwire 0x4c10a0
code   0x4c10b0 obj_hook type 69 OWNER-DISPATCH (tag; huitzil 0x4274b0, pyron 0x4808e0; unknown owner -> tripwire 0x4c10a0)
code   0x4c10e0 ILLEGAL  TRIPWIRE for unresolved 0x68768
# obj_hook@0x54470 type 70 owner-dispatch fallback: unresolved 0x68768 -> tripwire 0x4c10e0
code   0x4c10f0 obj_hook type 70 OWNER-DISPATCH (tag; huitzil 0x4277c0, pyron 0x480bf0; unknown owner -> tripwire 0x4c10e0)
code   0x4c1120 ILLEGAL  TRIPWIRE for unresolved 0x689cc
# obj_hook@0x54470 type 71 owner-dispatch fallback: unresolved 0x689cc -> tripwire 0x4c1120
code   0x4c1130 obj_hook type 71 OWNER-DISPATCH (tag; huitzil 0x427a30, pyron 0x480e60; unknown owner -> tripwire 0x4c1120)
code   0x4c1160 ILLEGAL  TRIPWIRE for unresolved 0x68c78
# obj_hook@0x54470 type 72 owner-dispatch fallback: unresolved 0x68c78 -> tripwire 0x4c1160
code   0x4c1170 obj_hook type 72 OWNER-DISPATCH (tag; huitzil 0x427ce0, pyron 0x481110; unknown owner -> tripwire 0x4c1160)
code   0x4c11a0 ILLEGAL  TRIPWIRE for unresolved 0x69046
# obj_hook@0x54470 type 73 owner-dispatch fallback: unresolved 0x69046 -> tripwire 0x4c11a0
code   0x4c11b0 obj_hook type 73 OWNER-DISPATCH (tag; huitzil 0x4280b0, pyron 0x4814e0; unknown owner -> tripwire 0x4c11a0)
#   obj_hook@0x54470 type 73: stamp sites also exist in donovan (no handler copy placed) — a live spawn there would tripwire under its OWN tag; solo builds already tripwire this type for them and playtest green (dead paths)
code   0x4c11e0 ILLEGAL  TRIPWIRE for unresolved 0x692f6
# obj_hook@0x54470 type 74 owner-dispatch fallback: unresolved 0x692f6 -> tripwire 0x4c11e0
code   0x4c11f0 obj_hook type 74 OWNER-DISPATCH (tag; huitzil 0x428360, pyron 0x481790; unknown owner -> tripwire 0x4c11e0)
code   0x4c1220 ILLEGAL  TRIPWIRE for unresolved 0x6965e
# obj_hook@0x54470 type 75 owner-dispatch fallback: unresolved 0x6965e -> tripwire 0x4c1220
code   0x4c1230 obj_hook type 75 OWNER-DISPATCH (tag; huitzil 0x4286d0, pyron 0x481b00; unknown owner -> tripwire 0x4c1220)
#   obj_hook@0x54470 type 75: stamp sites also exist in donovan (no handler copy placed) — a live spawn there would tripwire under its OWN tag; solo builds already tripwire this type for them and playtest green (dead paths)
code   0x4c1260 +0x15c  obj_walker: 0x54458 relocated verbatim + its extended type table at +0x2c (59 vanilla + 17 ported, 17 placed); dispatch site 0x54470 left VANILLA
code   2 caller operand(s) of jsr 0x54458 -> 0x4c1260 (0x009436, 0x020310)
#   obj_hook@0x5e542 type 114 original entry serves FIRST resolver donovan 0xd0170 by design (14z-82); renumbered: huitzil->124, pyron->125
#   obj_hook@0x5e542 type 115 original entry serves FIRST resolver donovan 0xd142a by design (14z-82); renumbered: huitzil->126, pyron->127
#   obj_hook@0x5e542 type 116 original entry serves FIRST resolver donovan 0xd1ecc by design (14z-82); renumbered: huitzil->128, pyron->129
#   obj_hook@0x5e542 type 117 original entry serves FIRST resolver donovan 0xd224a by design (14z-82); renumbered: huitzil->130, pyron->131
#   obj_hook@0x5e542 type 118 original entry serves FIRST resolver donovan 0xd2956 by design (14z-82); renumbered: huitzil->132, pyron->133
#   obj_hook@0x5e542 type 119 original entry serves FIRST resolver donovan 0xd2d38 by design (14z-82); renumbered: huitzil->134, pyron->135
#   obj_hook@0x5e542 type 120 MULTI-RESOLVER (donovan, huitzil, pyron) with no measured owner-read -> FIRST-WINS (donovan 0xd2e5a); order-dependent — measure it (tests/audit_objhook_owner_census.sh) and extend OBJ_HOOK_OWNER_READ
code   0x4c13c0 ILLEGAL  TRIPWIRE for unresolved 0x6a70c
# obj_hook@0x5e542 type 121: unresolved 0x6a70c -> tripwire 0x4c13c0
# obj_hook@0x5e542 type 122: unresolved 0x6a70c -> tripwire 0x4c13c0
# obj_hook@0x5e542 type 123: unresolved 0x6a70c -> tripwire 0x4c13c0
#   obj_hook renumbered type 124 = huitzil's 114 -> 0x4296f0 (its OWN copy; stamps rewritten in-region, 14z-82)
#   obj_hook renumbered type 125 = pyron's 114 -> 0x481c00 (its OWN copy; stamps rewritten in-region, 14z-82)
#   obj_hook renumbered type 126 = huitzil's 115 -> 0x42a9aa (its OWN copy; stamps rewritten in-region, 14z-82)
#   obj_hook renumbered type 127 = pyron's 115 -> 0x482eba (its OWN copy; stamps rewritten in-region, 14z-82)
#   obj_hook renumbered type 128 = huitzil's 116 -> 0x42b44c (its OWN copy; stamps rewritten in-region, 14z-82)
#   obj_hook renumbered type 129 = pyron's 116 -> 0x48395c (its OWN copy; stamps rewritten in-region, 14z-82)
#   obj_hook renumbered type 130 = huitzil's 117 -> 0x42b7ca (its OWN copy; stamps rewritten in-region, 14z-82)
#   obj_hook renumbered type 131 = pyron's 117 -> 0x483cda (its OWN copy; stamps rewritten in-region, 14z-82)
#   obj_hook renumbered type 132 = huitzil's 118 -> 0x42bed6 (its OWN copy; stamps rewritten in-region, 14z-82)
#   obj_hook renumbered type 133 = pyron's 118 -> 0x4843e6 (its OWN copy; stamps rewritten in-region, 14z-82)
#   obj_hook renumbered type 134 = huitzil's 119 -> 0x42c2b8 (its OWN copy; stamps rewritten in-region, 14z-82)
#   obj_hook renumbered type 135 = pyron's 119 -> 0x4847c8 (its OWN copy; stamps rewritten in-region, 14z-82)
code   0x4c13d0 +0x24c  obj_walker: 0x5e52a relocated verbatim + its extended type table at +0x2c (114 vanilla + 10 ported, 7 placed, 12 renumbered); dispatch site 0x5e542 left VANILLA
code   21 caller operand(s) of jsr 0x5e52a -> 0x4c13d0 (0x0053f6, 0x005410, 0x00577c, 0x0057a8, 0x00590a, 0x005ebc, 0x00943c, 0x009caa, 0x009f36, 0x00a188, 0x00a804, 0x00abcc, 0x010dfa, 0x012a3e, 0x012d16, 0x012e4c, 0x012e66, 0x020316, 0x021638, 0x021ada, 0x021dea)
poke32 0x0bd13e <- 0x004737e4  dispatch_00[0x11] donovan handler
poke32 0x0bd1be <- 0x0047188e  dispatch_01[0x11] donovan handler
poke32 0x0bd23e <- 0x004720b0  dispatch_02[0x11] donovan handler
poke32 0x0bd2be <- 0x004720b0  dispatch_03[0x11] donovan handler
poke32 0x0bd33e <- 0x004720b0  dispatch_04[0x11] donovan handler
poke32 0x0bd3be <- 0x00473192  dispatch_05[0x11] donovan handler
poke32 0x0bd43e <- 0x00471c12  dispatch_06[0x11] donovan handler
poke32 0x0bd53e <- 0x00472034  dispatch_08[0x11] donovan handler
poke32 0x0bd5be <- 0x00471d82  dispatch_09[0x11] donovan handler
poke32 0x0bd63e <- 0x00471b80  dispatch_10[0x11] donovan handler
poke32 0x0bd6be <- 0x004735dc  dispatch_11[0x11] donovan handler
poke32 0x0bd73e <- 0x004736fa  dispatch_12[0x11] donovan handler
poke32 0x0bd7be <- 0x004737ae  dispatch_13[0x11] donovan handler
poke32 0x0bd83e <- 0x0047339c  dispatch_14[0x11] donovan handler
poke32 0x0bf25e <- 0x00471d00  dispatch_15[0x11] donovan handler
poke32 0x0bf35e <- 0x004730e8  dispatch_16[0x11] donovan handler
poke32 0x0bf3de <- 0x00473150  dispatch_17[0x11] donovan handler
poke32 0x0bf4de <- 0x00473822  dispatch_18[0x11] donovan handler
poke32 0x0bf65e <- 0x00473186  dispatch_19[0x11] donovan handler
poke16 0x0898a6 <- 0x869c  aux hud_mug_entry_11
poke32 0x08994c <- 0x86940102  aux hud_name_entry_11_hi
poke32 0x089950 <- 0xfff00002  aux hud_name_entry_11_lo
data   0x00b6a8 +0x40  data_port voice_borrow_candidates_a <- vsav2 0x009f6a (0 fixes)
data   0x00bfa8 +0x40  data_port voice_borrow_voicenums_b <- vsav2 0x00a86a (4 fixes)
data   0x4c1620 +0xb8  sound_table pyr_sfx_records <- vsav2 0x0c8b18 (23 entries; kept ['0x110@1', '0x111@3', '0x112@4', '0x0a4@5', '0x0a5@6', '0x097@7', '0x0a0@8', '0x0a1@9', '0x0a2@10', '0x0a1@11', '0x0a3@12', '0x09e@13', '0x0a6@16', '0x09a@18', '0x202@21']; zeroed 6 unplayable ids; remapped [(5, '0x72d', '0xa4'), (6, '0x72e', '0xa5'), (7, '0x720', '0x97'), (8, '0x729', '0xa0'), (9, '0x72a', '0xa1'), (10, '0x72b', '0xa2'), (11, '0x72a', '0xa1'), (12, '0x72c', '0xa3'), (13, '0x727', '0x9e'), (16, '0x72f', '0xa6'), (18, '0x723', '0x9a')])
poke32 0x0bf45e <- 0x4c1620  sound_table pyr_sfx_records per-char ptr row 0x11 (was 0x95894)
data   0x4c16e0 +0x20  select_records portrait/p1 coord list (8 pairs, vs2 0x3036b8)
data   0x4c1700 +0x2a  select_records portrait/p1 record (vs2 0x2a639c, 8 entries, budget 0x61 = vs2's own)
poke32 0x26746e <- 0x4c1700  select_records portrait/p1 array row 0x11 (was 0x27195e, the base-half alias)
data   0x4c1730 +0x20  select_records portrait/p2 coord list (8 pairs, vs2 0x3036d8)
data   0x4c1750 +0x2a  select_records portrait/p2 record (vs2 0x2a63c6, 8 entries, budget 0x61 = vs2's own)
poke32 0x2674ee <- 0x4c1750  select_records portrait/p2 array row 0x11 (was 0x271d70, the base-half alias)
data   0x4c1780 +0x4  select_records name_banner/p1 coord list (1 pairs, vs2 0x2fd9b4)
data   0x4c1790 +0xe  select_records name_banner/p1 record (vs2 0x2a6570, 1 entries, budget 0x6 = vs2's own)
poke32 0x2675ee <- 0x4c1790  select_records name_banner/p1 array row 0x11 (was 0x272156, the base-half alias)
data   0x4c17a0 +0x8  select_records name_banner/p2 coord list (2 pairs, vs2 0x303d9c)
data   0x4c17b0 +0x12  select_records name_banner/p2 record (vs2 0x2a7680, 2 entries, budget 0x3 = vs2's own)
poke32 0x26766e <- 0x4c17b0  select_records name_banner/p2 array row 0x11 (was 0x273060, the base-half alias)
data   0x4c17d0 +0x14  select_records splash_p1/p1 coord list (5 pairs, vs2 0x30437c)
data   0x4c17f0 +0x1e  select_records splash_p1/p1 record (vs2 0x2a7f2c, 5 entries, budget 0x4f = vs2's own)
poke32 0x2672ee <- 0x4c17f0  select_records splash_p1/p1 array row 0x11 (was 0x273494, the base-half alias)
data   0x4c1810 +0x14  select_records splash_p2/p1 coord list (5 pairs, vs2 0x304390)
data   0x4c1830 +0x1e  select_records splash_p2/p1 record (vs2 0x2a7f4a, 5 entries, budget 0x4f = vs2's own)
poke32 0x26736e <- 0x4c1830  select_records splash_p2/p1 array row 0x11 (was 0x2737da, the base-half alias)
data   0x4c1850 +0x38  select_records win_quote/p1 coord list (14 pairs, vs2 0x305034)
data   0x4c1890 +0x42  select_records win_quote/p1 record (vs2 0x2a8cb6, 14 entries, budget 0xb5 = vs2's own)
poke32 0x2673ee <- 0x4c1890  select_records win_quote/p1 array row 0x11 (was 0x273b68, the base-half alias)
poke32 0x268a46 <- 0x2724a2  select_records highlight/p1 array row 0x11 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x2725dc)
poke32 0x268ac6 <- 0x2726ce  select_records highlight/p2 array row 0x11 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x272800)
# select_records: 0 bank-1 tile placements -> select_tiles.json (only the composed records' art; the slot-0x0F splash/win-quote families are NOT placed, so that Jedah art stays vanilla)
# select_records: 287 native bank-1 tiles -> select_bank5.json (copied vs2 -> group C bank 5 by build_gfx; the drawer's bank is thunk-gated per hover)
data   0x4c18e0 +0x6040  win_pal_variant don_win_pal: sparse block, 10 sets of 0xa0 at stride 0xaa0 (vs2 0x3c365c stride 0xb40)
data   0x4c7920 +0x6040  win_pal_variant hui_win_pal: sparse block, 10 sets of 0xa0 at stride 0xaa0 (vs2 0x3c329c stride 0xb40)
data   0x4cd960 +0x6040  win_pal_variant pyr_win_pal: sparse block, 10 sets of 0xa0 at stride 0xaa0 (vs2 0x3c35bc stride 0xb40)
code   0x4d39a0 +0x32  win_pal_variant thunk, 3-way: don_win_pal d6==0x13 -> a0=0x4c0d00, hui_win_pal d6==0x10 -> a0=0x4c6f20, pyr_win_pal d6==0x11 -> a0=0x4ccec0; else vanilla pool 0x3ad700
code   0x05f1b6 +6     win_pal_variant: movea.l #pool -> jsr 0x4d39a0
# site_thunk name_bank_variant_id: body deferred to the 0x05fce0 chain (30 bytes)
# site_thunk splash_bank_variant_id: body deferred to the 0x06c0e0 chain (30 bytes)
# site_thunk winquote_bank_variant_id: body deferred to the 0x05f328 chain (22 bytes)
data   0x4d39e0 +0x140  site_thunk select_pal_variant_id data block <- vsav2 0x3c28fc
# site_thunk select_pal_variant_id: body deferred to the 0x05f146 chain (56 bytes)
code   0x4d3b20 +0x7c  site_thunk 3-way chain at 0x05f146: select_pal_variant_id, select_pal_variant_id, select_pal_variant_id (22 shared tail bytes)
code   0x4d3ba0 +0x32  site_thunk 3-way chain at 0x05f328: winquote_bank_variant_id, winquote_bank_variant_id, winquote_bank_variant_id (2 shared tail bytes)
code   0x4d3be0 +0x3e  site_thunk 3-way chain at 0x05fce0: name_bank_variant_id, name_bank_variant_id, name_bank_variant_id (8 shared tail bytes)
code   0x4d3c20 +0x3e  site_thunk 3-way chain at 0x06c0e0: splash_bank_variant_id, splash_bank_variant_id, splash_bank_variant_id (8 shared tail bytes)
code   0x4d3c60 ILLEGAL  TRIPWIRE for unresolved 0xf2f2f2
# init_shim chain fall-through (an id no declaring tenant claims): unresolved 0xf2f2f2 -> tripwire 0x4d3c60
code   0x4d3c70 MERGED init shim (pool latch A5+0x7966, seeder 0x16c64, phase-gated; flavor (A6+0x3c2) donovan<-0x01/held 0x00->handler 0xc1030, huitzil<-0x00/held 0x01->handler 0x416900 [Start bitmask 0xff8060]; unmatched id -> tripwire 0x4d3c60) planted on 2 dispatch rows (F2 fix)
poke32 0x0bd146 <- 0x004d3c70  dispatch_00[0x13] donovan handler via MERGED seed shim (F2)
poke32 0x0bd13a <- 0x004d3c70  dispatch_00[0x10] huitzil handler via MERGED seed shim (F2)
code   0x0282f6 +0x2  code_word obj_bank_word_slot (slot entry -> 1000)
code   0x05f244 +0x2  code_word win_pos_x_slot (slot entry -> 00c0)
code   0x05f246 +0x2  code_word win_pos_y_slot (slot entry -> 0094)
code   0x02a8c6 +0x2  code_word palette_routine_row_11 (008e -> 0040)
code   0x02b672 +0x2  code_word palette_routine_row_11_b (0042 -> 0040)
code   0x0737b2 +0x2  code_word palette_routine_row_11_c (0042 -> 0040)
code   0x003bf0 +0x2  code_word pyr_kernel_voice_e0 (0200 -> 0341)
code   0x003c5c +0x2  code_word pyr_kernel_voice_e1 (0201 -> 02a1)
code   0x003cc8 +0x2  code_word pyr_kernel_voice_e2 (0202 -> 02a2)
code   0x003d32 +0x2  code_word pyr_kernel_voice_e3 (0203 -> 0342)
# op poke16 0x028d4e +0x2 DROPPED: already written identically by ['data@0x28d4e']
# op poke16 0x028d50 +0x2 DROPPED: already written identically by ['data@0x28d50']
# op poke16 0x028d52 +0x2 DROPPED: already written identically by ['data@0x28d50']
# op data 0x0be88a +0x2 DROPPED: already written identically by ['data@0xbe88a']
# 4 agreeing duplicate op(s) dropped (identical bytes at the same address)
# M5: sfx helper 0x5122 UN-STUBBED -> vsavj 0x5fff00 (record array don_sfx_records is placed)
# M5: sfx helper 0x5122 UN-STUBBED -> vsavj 0x5fff00 (record array hui_sfx_records is placed)
# M5: sfx helper 0x5122 UN-STUBBED -> vsavj 0x5fff00 (record array pyr_sfx_records is placed)
# image: extend to 0x600000 (4 x 0x80000 member(s): vsw.41, vsw.42, vsw.43, vsw.44)
