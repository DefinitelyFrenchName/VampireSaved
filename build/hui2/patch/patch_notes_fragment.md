# donovan-m2 stage 2 — generated op notes

# stage 1: Jedah hitbox block 0x091E58+0x1C52 (base 0x91f98 comp 0x91e58)
data   0x0bf6a0 +0x1c52  jedah hitbox copy (null reloc)
# stage-1 scaffold repoints skipped: the stage-2+ passive-data pass owns the hitbox rows (14z-65)
code   0x0c1300 jmp 0x02fa08  dispatch_00 trampoline (hole a)
poke32 0x0bd13a <- 0x000c1300  dispatch_00[0x10] -> trampoline (hole a)
code   0x3ec720 jmp 0x02d644  dispatch_01 trampoline (hole b)
poke32 0x0bd1ba <- 0x003ec720  dispatch_01[0x10] -> trampoline (hole b)
data_file 0x0c1310 +0x32b2  donovan hitbox (from vsav2 0x0C4250)
data_file 0x0c45d0 +0x3c6  donovan hitbox_proj (from vsav2 0x0D05C0)
# anim_index_a: region anim not placed at stage 2 — repoint deferred
# anim_index_a2: region anim not placed at stage 2 — repoint deferred
# anim_index_b: region anim not placed at stage 2 — repoint deferred
# anim_index_c: region anim not placed at stage 2 — repoint deferred
# anim_index_proj: region anim not placed at stage 2 — repoint deferred
# param32_a: velocity pair NOT ported (14w-b crash guard; Jedah speeds retained)
poke32 0x0bd9ba <- 0x000c1430  hitbox_base[0x10] donovan hitbox
poke32 0x0bda3a <- 0x000c1310  hitbox_comp[0x10] donovan hitbox
poke32 0x0bdaba <- 0x000c4604  proj_hitbox_base[0x10] donovan hitbox_proj
poke32 0x0bdb3a <- 0x000c45d0  proj_hitbox_comp[0x10] donovan hitbox_proj
data   0x0bdbfa +0x8  rec8_a[0x10] value
data   0x0be19a +0x2  word132[0x10] value
data   0x0be1da +0x2  word_pos_a[0x10] value
data   0x0be21a +0x2  word_pos_b[0x10] value
# param32_b: velocity pair NOT ported (14w-b crash guard; Jedah speeds retained)
data   0x0be47a +0x8  rec8_b[0x10] value
data   0x0be81a +0x2  word_y_off[0x10] value
data   0x0be85a +0x2  word_range[0x10] value
data   0x0be88a +0x2  byte15b[0x10] value
data   0x0bea7a +0x1e  byte2d_a[0x10] value
data   0x0bee3a +0x1e  byte2d_b[0x10] value
# tail_code_ptr: region x055478 not placed at stage 2 — repoint deferred
poke32 0x0bf45a <- 0x000c44ea  tail_data_ptr[0x10] donovan hitbox
