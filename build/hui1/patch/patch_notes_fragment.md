# donovan-m2 stage 1 — generated op notes

# stage 1: Jedah hitbox block 0x091E58+0x1C52 (base 0x91f98 comp 0x91e58)
data   0x0bf6a0 +0x1c52  jedah hitbox copy (null reloc)
poke32 0x0bd9ba <- 0x000bf7e0  hitbox_base[0x10] null reloc
poke32 0x0bda3a <- 0x000bf6a0  hitbox_comp[0x10] null reloc
code   0x0c1300 jmp 0x02fa08  dispatch_00 trampoline (hole a)
poke32 0x0bd13a <- 0x000c1300  dispatch_00[0x10] -> trampoline (hole a)
code   0x3ec720 jmp 0x02d644  dispatch_01 trampoline (hole b)
poke32 0x0bd1ba <- 0x003ec720  dispatch_01[0x10] -> trampoline (hole b)
