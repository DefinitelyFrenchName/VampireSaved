# donovan-m2 stage 6 — generated op notes

# stage 1: Jedah hitbox block 0x093AAA+0x0 (base 0x93b6a comp 0x93aaa)
# table_fix: region x026142 len 0x1400 -> 0x1440 (ported per-char OBJ bank table -> vanilla vsavj values + row 0x11 = WIDE bank 4)
data_file 0x0d3560 +0x1b500  donovan anim (from vsav2 0x264086)
data_file 0x0eea60 +0x190  donovan aux0_0 (from vsav2 0x334170)
data_file 0x0eebf0 +0x190  donovan aux0_1 (from vsav2 0x33CD00)
data_file 0x0eed80 +0xd830  donovan aux0_2 (from vsav2 0x344A60)
code   0x0fe8c0 farm-port stub for 0x2916c (param at 0x0fe8a0, common 0x29f4a)
code   0x0fe8e0 farm-port stub for 0x2915c (param at 0x0fe8d0, common 0x29f4a)
code   0x0fe900 farm-port stub for 0x29164 (param at 0x0fe8f0, common 0x29f4a)
code   0x0fe920 farm-port stub for 0x29184 (param at 0x0fe910, common 0x29f4a)
code   0x0fe940 farm-port stub for 0x2918c (param at 0x0fe930, common 0x29f4a)
code   0x0fe950 slot-clearing alloc wrapper for 0x15702 -> 0x16fba (0x80 cleared, +8 preserved)
code   0x0fe980 slot-clearing alloc wrapper for 0x1572e -> 0x16fe6 (0x80 cleared, +8 preserved)
code   0x0fe9b0 ILLEGAL  TRIPWIRE for unresolved 0x4223c
# code+0x3ad8: unresolved 0x4223c -> tripwire 0xfe9b0
code   0x0fe9c0 ILLEGAL  TRIPWIRE for unresolved 0x42cee
# code+0x41b0: unresolved 0x42cee -> tripwire 0xfe9c0
code   0x0fe9d0 ILLEGAL  TRIPWIRE for unresolved 0x448d4
# code+0x5062: unresolved 0x448d4 -> tripwire 0xfe9d0
# code+0x1ecc: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (P own code zone): vs2 bank 3 -> WIDE bank 4)
# code+0x1ee: data_in_code [pointer-inline] lea.l #0x3f7930,a2 in place (DATA view of vsav2 0x0576f4; air-dive per-strength (xv,yv) rows; a2 re-derived by `lea (a2,d2.w),a2`)
code_file 0x0bf6a0 +0x5200  donovan code (from vsav2 0x0574C0)
data_file 0x0fc5b0 +0x16b6  donovan hitbox (from vsav2 0x0C7502)
data_file 0x0fdc70 +0x322  donovan hitbox_proj (from vsav2 0x0D0986)
# x026142+0x1410: bank table row 0x11 <- 0x1000 (bank 4, WIDE encoding; vanilla row was 0x1000) — tenant-driven
# x026142+0x13ee: table_fix 48 bytes (ported per-char OBJ bank table -> vanilla vsavj values + row 0x11 = WIDE bank 4)
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
code_file 0x0c48a0 +0x14a0  donovan x026142 (from vsav2 0x026142)
# bank_ref 0xd6ebe -> 0xbcd20 (delta rule, 16B byte-identical)
# bank_ref 0xd699e -> 0xbc800 (delta rule, 16B byte-identical)
# bank_ref 0xd671e -> 0xbc580 (delta rule, 16B byte-identical)
# bank_ref 0xd671e -> 0xbc580 (delta rule, 16B byte-identical)
# bank_ref 0xd679e -> 0xbc600 (delta rule, 16B byte-identical)
# bank_ref 0xd679e -> 0xbc600 (delta rule, 16B byte-identical)
code_file 0x0c5d40 +0xe00  donovan x028122 (from vsav2 0x028122)
code   0x0fe9e0 ILLEGAL  TRIPWIRE for unresolved 0x12f484
# x05c800+0x152a: unresolved 0x12f484 -> tripwire 0xfe9e0
# x05c800+0x16a4: unresolved 0x12f484 -> tripwire 0xfe9e0
code   0x0fe9f0 ILLEGAL  TRIPWIRE for unresolved 0x167bf4
# x05c800+0x2622: unresolved 0x167bf4 -> tripwire 0xfe9f0
# x05c800+0x2a20: unresolved 0x167bf4 -> tripwire 0xfe9f0
code   0x0fea00 ILLEGAL  TRIPWIRE for unresolved 0x17f176
# x05c800+0x2ae4: unresolved 0x17f176 -> tripwire 0xfea00
# x05c800+0x3034: unresolved 0x17f176 -> tripwire 0xfea00
code   0x0fea10 ILLEGAL  TRIPWIRE for unresolved 0x181592
# x05c800+0x3072: unresolved 0x181592 -> tripwire 0xfea10
# x05c800+0x738: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x05c800+0x58d4: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x05c800+0x5994: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# pcrel_escape_fix x05c800: 2 escapes -> 1 trampolines (0 tripwired), pad 0x6a00..0x6a20
code_file 0x0c6b40 +0x6a20  donovan x05c800 (from vsav2 0x05C800)
code_file 0x0cd560 +0x280  donovan x0672d0 (from vsav2 0x0672D0)
code_file 0x0cd7e0 +0x2f6  donovan x067550 (from vsav2 0x067550)
code_file 0x0cdae0 +0x1ba  donovan x067846 (from vsav2 0x067846)
code_file 0x0cdca0 +0x60c  donovan x067a00 (from vsav2 0x067A00)
# x06800c+0x354: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x396: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x3de: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
# x06800c+0x422: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
code_file 0x0ce2b0 +0x44c  donovan x06800c (from vsav2 0x06800C)
code_file 0x0ce700 +0x310  donovan x068458 (from vsav2 0x068458)
code_file 0x0cea10 +0x264  donovan x068768 (from vsav2 0x068768)
code_file 0x0cec80 +0x2ac  donovan x0689cc (from vsav2 0x0689CC)
code   0x0fea20 +0x40  patched clone of 0x5459a for vs2 0x5c77e (unmasked set-anim entry; false byte-matc)
code_file 0x0cef30 +0x3ce  donovan x068c78 (from vsav2 0x068C78)
code_file 0x0cf300 +0x2b0  donovan x069046 (from vsav2 0x069046)
# x0692f6+0x19a: port_patch 397c60000018 -> 397c10000018 (OBJ bank setter (shared zone): vs2 bank 3 -> WIDE bank 4)
code_file 0x0cf5b0 +0x368  donovan x0692f6 (from vsav2 0x0692F6)
code_file 0x0cf920 +0x100  donovan x06965e (from vsav2 0x06965E)
code   0x0fea60 ILLEGAL  TRIPWIRE for unresolved 0x281696
# x088512+0x348: unresolved 0x281696 -> tripwire 0xfea60
code   0x0fea70 ILLEGAL  TRIPWIRE for unresolved 0x289b14
# x088512+0x126a: unresolved 0x289b14 -> tripwire 0xfea70
# x088512+0x127c: unresolved 0x289b14 -> tripwire 0xfea70
code   0x0fea80 ILLEGAL  TRIPWIRE for unresolved 0x24edd4
# x088512+0x1362: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x13a0: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x13e4: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x1428: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x1464: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x14a2: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x150a: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x154e: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x1590: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x15f0: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x1670: unresolved 0x24edd4 -> tripwire 0xfea80
code   0x0fea90 ILLEGAL  TRIPWIRE for unresolved 0x24a3ce
# x088512+0x16d8: unresolved 0x24a3ce -> tripwire 0xfea90
# x088512+0x1732: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x1796: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x17fa: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x18ee: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x191c: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x194a: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x1994: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x1cd2: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x1d1a: unresolved 0x24edd4 -> tripwire 0xfea80
code   0x0feaa0 ILLEGAL  TRIPWIRE for unresolved 0x28ed08
# x088512+0x1de2: unresolved 0x28ed08 -> tripwire 0xfeaa0
code   0x0feab0 ILLEGAL  TRIPWIRE for unresolved 0x36784a
# x088512+0x1dee: unresolved 0x36784a -> tripwire 0xfeab0
code   0x0feac0 ILLEGAL  TRIPWIRE for unresolved 0x25111e
# x088512+0x2156: unresolved 0x25111e -> tripwire 0xfeac0
# x088512+0x21d2: unresolved 0x25111e -> tripwire 0xfeac0
# x088512+0x26e2: unresolved 0x25111e -> tripwire 0xfeac0
# x088512+0x28ce: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x290c: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x294a: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x2986: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x29c4: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x2a2c: unresolved 0x24edd4 -> tripwire 0xfea80
# x088512+0x2a6a: unresolved 0x24edd4 -> tripwire 0xfea80
code   0x0fead0 ILLEGAL  TRIPWIRE for unresolved 0x2abd58
# x088512+0x359c: unresolved 0x2abd58 -> tripwire 0xfead0
# x088512+0x2be6: port_patch 000e -> 000c (companion queue class 7 (vs2-only) -> vsavj class 6 (the Anita/H precedent))
# x088512+0x22c: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter (pod/companion zone): vs2 bank 3 -> WIDE bank 4)
# x088512+0x1814: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter (pod/companion zone): vs2 bank 3 -> WIDE bank 4)
# x088512+0x2bee: port_patch 3d7c60000018 -> 3d7c10000018 (OBJ bank setter (pod/companion zone): vs2 bank 3 -> WIDE bank 4)
# x088512+0x3ae4: data_in_code reroute -> helper 0x3f7a40, table 0x3f7940 (DATA view of vsav2 0x08c042; pod-zone word offset/record table (a3 re-derived from it; self-relative; shared-zone copy))
code_file 0x0cfa20 +0x3b40  donovan x088512 (from vsav2 0x088512)
data_file 0x0fdfa0 +0x900  donovan x0d143e (from vsav2 0x0D143E)
code   0x0feae0 ILLEGAL  TRIPWIRE for unresolved 0x2c3136
# x2b7ef4+0xb0c9: unresolved 0x2c3136 -> tripwire 0xfeae0
code   0x0feaf0 ILLEGAL  TRIPWIRE for unresolved 0x2c3170
# x2b7ef4+0xb0d1: unresolved 0x2c3170 -> tripwire 0xfeaf0
code   0x0feb00 ILLEGAL  TRIPWIRE for unresolved 0x2c31aa
# x2b7ef4+0xb0d9: unresolved 0x2c31aa -> tripwire 0xfeb00
code   0x0feb10 ILLEGAL  TRIPWIRE for unresolved 0x2c31e4
# x2b7ef4+0xb0fd: unresolved 0x2c31e4 -> tripwire 0xfeb10
code   0x0feb20 ILLEGAL  TRIPWIRE for unresolved 0x2c3236
# x2b7ef4+0xb105: unresolved 0x2c3236 -> tripwire 0xfeb20
code   0x0feb30 ILLEGAL  TRIPWIRE for unresolved 0x2c325c
# x2b7ef4+0xb10d: unresolved 0x2c325c -> tripwire 0xfeb30
code   0x0feb40 ILLEGAL  TRIPWIRE for unresolved 0x2c3272
# x2b7ef4+0xb115: unresolved 0x2c3272 -> tripwire 0xfeb40
code   0x0feb50 ILLEGAL  TRIPWIRE for unresolved 0x2c3280
# x2b7ef4+0xb11d: unresolved 0x2c3280 -> tripwire 0xfeb50
code   0x0feb60 ILLEGAL  TRIPWIRE for unresolved 0x2c3296
# x2b7ef4+0xb125: unresolved 0x2c3296 -> tripwire 0xfeb60
code   0x0feb70 ILLEGAL  TRIPWIRE for unresolved 0x2c32a4
# x2b7ef4+0xb12d: unresolved 0x2c32a4 -> tripwire 0xfeb70
code   0x0feb80 ILLEGAL  TRIPWIRE for unresolved 0x2c32b2
# x2b7ef4+0xb135: unresolved 0x2c32b2 -> tripwire 0xfeb80
# x2b7ef4: effect-c5 — 5714 bank-1 codes kept NATIVE (art -> group C bank 5); 114 coord lists matched, 617 ported (11336B fragment)
data_file 0x3ec720 +0xb20c  donovan x2b7ef4 (from vsav2 0x2B7EF4)
data     0x3fa6a0 +0x500  sprite palette block (vsav2 0x39C19C); poke32 0x38c1dc (table 0x38c198 row 0x11)
poke32 0x0bcebe <- 0x000d3560  anim_index_a[0x11] donovan anim
poke32 0x0bcf3e <- 0x000d8aaa  anim_index_a2[0x11] donovan anim
poke32 0x0bcfbe <- 0x000d5a2e  anim_index_b[0x11] donovan anim
poke32 0x0bd03e <- 0x000d54aa  anim_index_c[0x11] donovan anim
poke32 0x0bd0be <- 0x000dca8e  anim_index_proj[0x11] donovan anim
data   0x0bd902 +0x8  param32_a[0x11] value
data   0x0bdeaa +0x30  jump_params[0x11] value
poke32 0x0bd9be <- 0x000fc6ac  hitbox_base[0x11] donovan hitbox
poke32 0x0bda3e <- 0x000fc5b0  hitbox_comp[0x11] donovan hitbox
poke32 0x0bdabe <- 0x000fdc78  proj_hitbox_base[0x11] donovan hitbox_proj
poke32 0x0bdb3e <- 0x000fdc70  proj_hitbox_comp[0x11] donovan hitbox_proj
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
poke32 0x0bf2de <- 0x000bfc92  tail_code_ptr[0x11] donovan code
poke32 0x0bf45e <- 0x000fdbc6  tail_data_ptr[0x11] donovan hitbox
poke32 0x0bd4be <- 0x00024ea4  dispatch_07[0x11] engine twin of 0x23afe (alias char row 0x30b9a differs)
code   0x0feb90 ILLEGAL  TRIPWIRE for unresolved 0x65c22
# obj_hook@0x54470 type 59: unresolved 0x65c22 -> tripwire 0xfeb90
code   0x0feba0 ILLEGAL  TRIPWIRE for unresolved 0x65e5a
# obj_hook@0x54470 type 60: unresolved 0x65e5a -> tripwire 0xfeba0
# obj_hook@0x54470 type 61: unresolved 0x65e5a -> tripwire 0xfeba0
code   0x0febb0 ILLEGAL  TRIPWIRE for unresolved 0x66ec4
# obj_hook@0x54470 type 62: unresolved 0x66ec4 -> tripwire 0xfebb0
code   0x0febc0 ILLEGAL  TRIPWIRE for unresolved 0x6717c
# obj_hook@0x54470 type 63: unresolved 0x6717c -> tripwire 0xfebc0
data   0x0febd0 +0x130  proj_hook extended type table (59 vanilla + 17 ported, 12 placed)
code   0x0fed00 obj_hook thunk (ghost-clean: returns to vanilla jsr)
code   0x054470 ENGINE HOOK: dispatch -> jmp thunk; vanilla jsr (A0) at 0x54476 untouched (vanilla types identical via table copy)
code   0x0fed20 ILLEGAL  TRIPWIRE for unresolved 0x6a70c
# obj_hook@0x5e542 type 121: unresolved 0x6a70c -> tripwire 0xfed20
# obj_hook@0x5e542 type 122: unresolved 0x6a70c -> tripwire 0xfed20
# obj_hook@0x5e542 type 123: unresolved 0x6a70c -> tripwire 0xfed20
data   0x0fed30 +0x1f0  proj_hook extended type table (114 vanilla + 10 ported, 7 placed)
code   0x0fef20 obj_hook thunk (ghost-clean: returns to vanilla jsr)
code   0x05e542 ENGINE HOOK: dispatch -> jmp thunk; vanilla jsr (A0) at 0x5e548 untouched (vanilla types identical via table copy)
poke32 0x0bd13e <- 0x000c1604  dispatch_00[0x11] donovan handler
poke32 0x0bd1be <- 0x000bf6ae  dispatch_01[0x11] donovan handler
poke32 0x0bd23e <- 0x000bfed0  dispatch_02[0x11] donovan handler
poke32 0x0bd2be <- 0x000bfed0  dispatch_03[0x11] donovan handler
poke32 0x0bd33e <- 0x000bfed0  dispatch_04[0x11] donovan handler
poke32 0x0bd3be <- 0x000c0fb2  dispatch_05[0x11] donovan handler
poke32 0x0bd43e <- 0x000bfa32  dispatch_06[0x11] donovan handler
poke32 0x0bd53e <- 0x000bfe54  dispatch_08[0x11] donovan handler
poke32 0x0bd5be <- 0x000bfba2  dispatch_09[0x11] donovan handler
poke32 0x0bd63e <- 0x000bf9a0  dispatch_10[0x11] donovan handler
poke32 0x0bd6be <- 0x000c13fc  dispatch_11[0x11] donovan handler
poke32 0x0bd73e <- 0x000c151a  dispatch_12[0x11] donovan handler
poke32 0x0bd7be <- 0x000c15ce  dispatch_13[0x11] donovan handler
poke32 0x0bd83e <- 0x000c11bc  dispatch_14[0x11] donovan handler
poke32 0x0bf25e <- 0x000bfb20  dispatch_15[0x11] donovan handler
poke32 0x0bf35e <- 0x000c0f08  dispatch_16[0x11] donovan handler
poke32 0x0bf3de <- 0x000c0f70  dispatch_17[0x11] donovan handler
poke32 0x0bf4de <- 0x000c1642  dispatch_18[0x11] donovan handler
poke32 0x0bf65e <- 0x000c0fa6  dispatch_19[0x11] donovan handler
poke16 0x0898a6 <- 0x869c  aux hud_mug_entry_11
poke32 0x08994c <- 0x86940102  aux hud_name_entry_11_hi
poke32 0x089950 <- 0xfff00002  aux hud_name_entry_11_lo
data   0x0211e4        select_wheel roster21: TABLE B in place, 28 bytes over 3 new rows + 5 inbound edges
data   0x400010 +0x54  select_wheel roster21 coord list (18 vanilla + 3 new)
data   0x400070 +0x5e  select_wheel roster21 record (count 17->20, budget 0x55 CARRIED OVER, cptr -> 0x400010)
poke32 0x2689fe <- 0x400070  select_wheel roster21 record ptr (was 0x272a68; the record's ONLY referrer — vanilla record and list are untouched)
code   0x05fb22 +4     select_wheel roster21: highlight base row 0x10 <- (158,80) (was the row 0x00 alias)
code   0x05fb26 +4     select_wheel roster21: highlight base row 0x11 <- (188,72) (was the row 0x01 alias)
code   0x05fb2e +4     select_wheel roster21: highlight base row 0x13 <- (216,80) (was the row 0x03 alias)
# select_wheel roster21: 3 highlight base rows written in place (32-row aliased pc-rel table 0x5fae2; the vs2 precedent — its variant half is un-aliased for its newcomers)
poke32 0x268a42 <- 0x2724a2  select_wheel roster21: p1 highlight row 0x10 = host row 0x0f ring (ring_rows)
poke32 0x268a4e <- 0x2724a2  select_wheel roster21: p1 highlight row 0x13 = host row 0x0f ring (ring_rows)
poke32 0x268ac2 <- 0x2726ce  select_wheel roster21: p2 highlight row 0x10 = host row 0x0f ring (ring_rows)
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
code   0x0fef40 +0x28  select_wheel roster21: march mid-row retarget 0x16/0x19 -> 0x02 (dest computation 0x2b598 jsr-routed)
code   0x0fef70 +0x28  select_wheel roster21: march mid-row retarget 0x16/0x19 -> 0x02 (dest computation 0x2b7d8 jsr-routed)
data   0x4000d0 +0x20  select_records portrait/p1 coord list (8 pairs, vs2 0x3036b8)
data   0x4000f0 +0x2a  select_records portrait/p1 record (vs2 0x2a639c, 8 entries, budget 0x61 = vs2's own)
poke32 0x26746e <- 0x4000f0  select_records portrait/p1 array row 0x11 (was 0x27195e, the base-half alias)
data   0x400120 +0x20  select_records portrait/p2 coord list (8 pairs, vs2 0x3036d8)
data   0x400140 +0x2a  select_records portrait/p2 record (vs2 0x2a63c6, 8 entries, budget 0x61 = vs2's own)
poke32 0x2674ee <- 0x400140  select_records portrait/p2 array row 0x11 (was 0x271d70, the base-half alias)
data   0x400170 +0x4  select_records name_banner/p1 coord list (1 pairs, vs2 0x2fd9b4)
data   0x400180 +0xe  select_records name_banner/p1 record (vs2 0x2a6570, 1 entries, budget 0x6 = vs2's own)
poke32 0x2675ee <- 0x400180  select_records name_banner/p1 array row 0x11 (was 0x272156, the base-half alias)
data   0x400190 +0x8  select_records name_banner/p2 coord list (2 pairs, vs2 0x303d9c)
data   0x4001a0 +0x12  select_records name_banner/p2 record (vs2 0x2a7680, 2 entries, budget 0x3 = vs2's own)
poke32 0x26766e <- 0x4001a0  select_records name_banner/p2 array row 0x11 (was 0x273060, the base-half alias)
data   0x4001c0 +0x14  select_records splash_p1/p1 coord list (5 pairs, vs2 0x30437c)
data   0x4001e0 +0x1e  select_records splash_p1/p1 record (vs2 0x2a7f2c, 5 entries, budget 0x4f = vs2's own)
poke32 0x2672ee <- 0x4001e0  select_records splash_p1/p1 array row 0x11 (was 0x273494, the base-half alias)
data   0x400200 +0x14  select_records splash_p2/p1 coord list (5 pairs, vs2 0x304390)
data   0x400220 +0x1e  select_records splash_p2/p1 record (vs2 0x2a7f4a, 5 entries, budget 0x4f = vs2's own)
poke32 0x26736e <- 0x400220  select_records splash_p2/p1 array row 0x11 (was 0x2737da, the base-half alias)
data   0x400240 +0x38  select_records win_quote/p1 coord list (14 pairs, vs2 0x305034)
data   0x400280 +0x42  select_records win_quote/p1 record (vs2 0x2a8cb6, 14 entries, budget 0xb5 = vs2's own)
poke32 0x2673ee <- 0x400280  select_records win_quote/p1 array row 0x11 (was 0x273b68, the base-half alias)
poke32 0x268a46 <- 0x2724a2  select_records highlight/p1 array row 0x11 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x2725dc)
poke32 0x268ac6 <- 0x2726ce  select_records highlight/p2 array row 0x11 = the HOST row 0x0f ring record VERBATIM (host_ring; was 0x272800)
# select_records: 0 bank-1 tile placements -> select_tiles.json (only the composed records' art; the slot-0x0F splash/win-quote families are NOT placed, so that Jedah art stays vanilla)
# select_records: 287 native bank-1 tiles -> select_bank5.json (copied vs2 -> group C bank 5 by build_gfx; the drawer's bank is thunk-gated per hover)
data   0x4002d0 +0x4b00  win_pal_variant pyr_win_pal: sparse block, 8 sets of 0xa0 at stride 0xaa0 (vs2 0x3c35bc stride 0xb40)
code   0x0fefa0 +0x16  win_pal_variant pyr_win_pal thunk (d6==TT -> a0 = 0x3ff830; else vanilla pool 0x3ad700)
code   0x05f1b6 +6     win_pal_variant pyr_win_pal: movea.l #pool -> jsr 0xfefa0
code   0x0fefc0 +0x1e  site_thunk name_bank_variant_id; site 0x05fce0 jsr-routed
code   0x0fefe0 +0x1e  site_thunk splash_bank_variant_id; site 0x06c0e0 jsr-routed
code   0x0ff000 +0x16  site_thunk winquote_bank_variant_id; site 0x05f328 jsr-routed
data   0x404dd0 +0x140  site_thunk select_pal_variant_id data block <- vsav2 0x3c28fc
code   0x0ff020 +0x38  site_thunk select_pal_variant_id; site 0x05f146 jsr-routed
code   0x0282f6 +0x2  code_word obj_bank_word_slot (slot entry -> 1000)
code   0x05f244 +0x2  code_word win_pos_x_slot (slot entry -> 00c0)
code   0x05f246 +0x2  code_word win_pos_y_slot (slot entry -> 0094)
code   0x01850a +0x2  code_word cosmo_substate81 (0006 -> 0224)
# image: extend to 0x600000 (4 x 0x80000 member(s): vsw.41, vsw.42, vsw.43, vsw.44)
