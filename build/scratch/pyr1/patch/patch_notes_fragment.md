# donovan-m2 stage 1 — generated op notes

# stage 1: Jedah hitbox block 0x093AAA+0x1F6A (base 0x93b6a comp 0x93aaa)
data   0x0bf6a0 +0x1f6a  jedah hitbox copy (null reloc)
poke32 0x0bd9be <- 0x000bf760  hitbox_base[0x11] null reloc
poke32 0x0bda3e <- 0x000bf6a0  hitbox_comp[0x11] null reloc
code   0x0c1610 jmp 0x03134c  dispatch_00 trampoline (hole a)
poke32 0x0bd13e <- 0x000c1610  dispatch_00[0x11] -> trampoline (hole a)
code   0x3ec720 jmp 0x02fac8  dispatch_01 trampoline (hole b)
poke32 0x0bd1be <- 0x003ec720  dispatch_01[0x11] -> trampoline (hole b)
