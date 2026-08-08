# PING #10 ARTIFACT — DO NOT REBUILD IN PLACE

Fingerprint: **5c6dbe43e017cb4ee785ef27b63e4790bc9e0622**
Cut: 2026-08-08 (session 14z-68m)
Launch: `tools/run_hui_behavior.sh` (this is its default)

Both defects you named on the win screen are fixed, and I checked the
screen this time instead of inferring it from RAM.

## 1. Win-screen PALETTE — now his real one

**I had given him DONOVAN's palette.** Your side-by-side made that
findable. The win drawer remaps the char id through a byte table
(vs2 0x6B2F2) before indexing the palette pool; I read that table
through the wrong view and landed on row 0x11 colour-4, which is
Donovan's set. Your pointer to "look at how we corrected Donovan"
is what settled it — his frozen `vs2_src` 0x3C365C is exactly
pool + 0x11*0xA0, which proves the OPCODE view of that table is the
right one, and therefore H is row 0x0B = **0x3C329C**.

Self-check that now guards it: the last word of each palette row is a
marker equal to 5*row. H's rows carry 0x37-0x3B (5*0x0B); Donovan's
carry 0x55-0x59 (5*0x11). The block I had been using carried
0x55-0x59 — it was labelled as his all along and I had not looked.

Expected now: **bright gold / yellow / orange**, matching your VS2
capture (the magenta patches were simply the wrong palette).

## 2. Win-screen POSITION — the left shift, same fix as Donovan's

You called this exactly right. The portrait's position comes from the
per-winner table at 0x5F200 (4 bytes/char, x then y). vsavj's row 0x10
is a plain alias (0x0080,0x0098); vs2's own row 0x10 is
(0x00C0,0x0080) — so he was drawn **64px too far left and 24px too
low**. Fixed with the same slot-following `code_word` mechanism as
Donovan's 14z-45 `win_pos` rows.

## STILL WRONG on this screen: the QUOTE TEXT

Native is robot-speak (敵 戦闘能力 ブンセキ / 類型データ ニ 格納中);
ours still shows a vanilla line. **Root cause found, not yet fixed:**
the quote fetch is `lea -4(a0,d0.w),a0`, so the consumer reads index
`0x60+id-1` = 0x6F, while our repointed row is 0x70 — an off-by-one
against a bias I had missed. His real records are vs2 0x2A5F36 (P1) /
0x2A6346 (P2), reachable via array bases 0x267426 / 0x2674A6. That is
the next change; it is well-specified and small.

## Everything else unchanged from ping #9

Still open, please don't re-report: the 236P beam and its family
(ES big beam, grab lightning, 214 explosion), the child companion's
rectangular shadow, Dark Force style, FG pacing.

Gates at cut, all PASS: boot (masked-v2 EXACT), ex, grab, air, pairs,
walk, m3a-reproducible, and **Donovan's own win-pal gate** (his track
is untouched by these rows). Frozen references rebuild bit-exact;
romset identity clean; hui11 reproduces its own fingerprint from the
manifest.

build/hui9 (ping #8) and build/hui10 (ping #9) stay pinned for A/B.
