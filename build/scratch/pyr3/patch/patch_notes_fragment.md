# donovan-m2 stage 3 — generated op notes

# stage 1: Jedah hitbox block 0x093AAA+0x1F6A (base 0x93b6a comp 0x93aaa)
data   0x0bf6a0 +0x1f6a  jedah hitbox copy (null reloc)
# stage-1 scaffold repoints skipped: the stage-2+ passive-data pass owns the hitbox rows (14z-65)
code   0x0c1610 jmp 0x03134c  dispatch_00 trampoline (hole a)
poke32 0x0bd13e <- 0x000c1610  dispatch_00[0x11] -> trampoline (hole a)
code   0x3ec720 jmp 0x02fac8  dispatch_01 trampoline (hole b)
poke32 0x0bd1be <- 0x003ec720  dispatch_01[0x11] -> trampoline (hole b)
data_file 0x0c1620 +0x1b500  donovan anim (from vsav2 0x264086)
data_file 0x0dcb20 +0x190  donovan aux0_0 (from vsav2 0x334170)
data_file 0x0dccb0 +0x190  donovan aux0_1 (from vsav2 0x33CD00)
data_file 0x0dce40 +0xd830  donovan aux0_2 (from vsav2 0x344A60)
data_file 0x0ea670 +0x16b6  donovan hitbox (from vsav2 0x0C7502)
data_file 0x0ebd30 +0x322  donovan hitbox_proj (from vsav2 0x0D0986)
poke32 0x0bcebe <- 0x000c1620  anim_index_a[0x11] donovan anim
poke32 0x0bcf3e <- 0x000c6b6a  anim_index_a2[0x11] donovan anim
poke32 0x0bcfbe <- 0x000c3aee  anim_index_b[0x11] donovan anim
poke32 0x0bd03e <- 0x000c356a  anim_index_c[0x11] donovan anim
poke32 0x0bd0be <- 0x000cab4e  anim_index_proj[0x11] donovan anim
# param32_a: velocity pair NOT ported (14w-b crash guard; Jedah speeds retained)
# jump_params: velocity pair NOT ported (14w-b crash guard; Jedah speeds retained)
poke32 0x0bd9be <- 0x000ea76c  hitbox_base[0x11] donovan hitbox
poke32 0x0bda3e <- 0x000ea670  hitbox_comp[0x11] donovan hitbox
poke32 0x0bdabe <- 0x000ebd38  proj_hitbox_base[0x11] donovan hitbox_proj
poke32 0x0bdb3e <- 0x000ebd30  proj_hitbox_comp[0x11] donovan hitbox_proj
data   0x0bdc02 +0x8  rec8_a[0x11] value
data   0x0be19c +0x2  word132[0x11] value
data   0x0be1dc +0x2  word_pos_a[0x11] value
data   0x0be21c +0x2  word_pos_b[0x11] value
# param32_b: velocity pair NOT ported (14w-b crash guard; Jedah speeds retained)
data   0x0be482 +0x8  rec8_b[0x11] value
data   0x0be81c +0x2  word_y_off[0x11] value
data   0x0be85c +0x2  word_range[0x11] value
data   0x0be88a +0x2  byte15b[0x11] value
data   0x0bea98 +0x1e  byte2d_a[0x11] value
data   0x0bee58 +0x1e  byte2d_b[0x11] value
# tail_code_ptr: region code not placed at stage 3 — repoint deferred
poke32 0x0bf45e <- 0x000ebc86  tail_data_ptr[0x11] donovan hitbox
