#!/bin/sh
# audit_mizuumi_rows_c.sh — THREE MORE MIZUUMI PLAYER-STRUCT CANDIDATES ON RIGS: +0x37F IS FELICIA'S 8-TICK HEADSIT
# LOCKOUT, SET WHEN SHE LEAVES A HEADSIT; +0x366 IS THE ZERO LOW WORD OF GALLON'S +0x364 LONG; +0xB2 IS THE ATTACKER'S
# DAMAGE MULTIPLIER (0 x1, 2 x1.25, 4 x0.5, 6 x0.25), SET TO 4 BY MORRIGAN'S AND LILITH'S MIRROR DARK FORCES
# (measured 14z-215, GitHub #118 batches B3, B4 and +0xB2; the maintainer read the capture sheets: B3 "correct", the
# +0xB2 halving "yes the damage is halved except for soul fist and finishing shower", the volleys "yes")
#
# WHAT: on pristine vsavj. B3 (P1 Felicia 0x07, P2 Victor 0x03): a forward jump after a 12-frame walk lands on standing
#   Victor's head (P1 state 0x02000E02, anim chain a2:0x5a) and she sits while he stays idle with no +0x37F write; she
#   leaves the headsit by one of three exits, each writing +0x37F := 8 once: PRG:0x0403AA when Victor leaves his idle
#   state (he crouches; the write 4 frames later), PRG:0x0403EE on a button (LP), PRG:0x040450 on a direction (Up);
#   PRG:0x03F3D2 then lowers it by one per engine tick (7..0, two in some frames) but only in the jump state 0x02000602:
#   after the button exit (state 0x02000606) it stays 8 through the landing and counts down only in her next jump; after
#   the Up exit she falls back on the head and sits again once it is 0; with +0x37F poked to 0x40 the frame after that
#   exit she does not sit again (the same fall); the same jump against CROUCHING Victor, a jump from 176 px and a jump
#   from 2 frames' walk closer never enter the headsit or write +0x37F; P2's +0x37F is never written in the match.
#   B4 (P1 Gallon 0x02): the air Beast Cannon writes the long +0x364 at PRG:0x032E62 (row 0, or row 1 when +0x102 = 6,
#   the ES version) and its down redirect at PRG:0x032EC0 (rows 0 and 1 the same way); every such write puts a non-zero
#   word at +0x364 and 0 at +0x366 in the same frame; the ground Beast Cannon (LP, HP, ES), its up redirect and the
#   diagonal one (623 LP, HP) never write +0x364..+0x367; +0x366 reads 0 on every match frame of every Gallon leg.
#   +0xB2 (P1 Morrigan 0x05 / Lilith 0x0E, P2 Victor idle, P1 HP at f3150 and f3300): with no Dark Force the HP lands one
#   hit, -11, and P1's +0xB2 is never written in the match; Morrigan's LP+LK Dark Force writes 4 to her +0xB2 at
#   PRG:0x039AAC and 4 to the double's (projectile slot 1) at PRG:0x056D28, cleared at PRG:0x039A84 at its end; each HP
#   then lands twice in one frame, the double's hit first (the scaler PRG:0x018BD4 reads slot 1's +0xB2, then P1's);
#   Morrigan's own hit loses 10 / 12 / 5 / 2 with her +0xB2 held at 0 / 2 / 4 / 6 (x1, x1.25, x0.5, x0.25 of 10); the
#   double's loses 5 with its +0xB2 4 and 11 held at 0; with no Dark Force and P1's +0xB2 held at 4 the hit loses 5
#   (11 >> 1); Lilith's HP+HK Dark Force (Mirror Doll) writes 4 at PRG:0x04DFF8 and 4 to slot 1 at PRG:0x05CA5C and
#   her two hits lose 5 and 5; her LP+LK one writes no P1 +0xB2, puts 6 in slot 1 (PRG:0x05CD26) and lands one hit, -11.
#   THE PROJECTILES (the maintainer's exception, 14z-215): in Morrigan's Dark Force a Soul Fist (236LP) spawns TWO
#   type-0x0B projectiles (one without it), each with +0xB2 := 0 at PRG:0x0546C2; the scaler reads each projectile's
#   own +0xB2 (0) before its hit, so the hits lose 10 and 9 (10 without Dark Force: unscaled) while P1's +0xB2 is 4;
#   the Finishing Shower (MP,LP,4,LK,MK) throws type-0x0D missiles, likewise +0xB2 := 0 at 0x0546C2 and read as 0
#   before every missile hit, 27 hits in the Dark Force against 15 without, the first five losing 3,3,3,2,2 in both.
# HOW: on MAME (the reference binary), replay 105's prologue (tests/replays/df/105_df_sas_armor.rpl's first eight lines,
#   the pair by the early-window poke), derived in-gate into one script per leg; a FIELD leg (tests/lua/field_trace.lua)
#   and a WRITE-TAP leg (tests/lua/read_tap.lua) per script, at most three MAME at once; one READ-TAP leg on the Morrigan
#   Dark Force script logs reads of P1's and slot 1's +0xB2 by PC 0x018BD4 (RPCS) in f3100-3400. Subject pokes: B3's
#   lockout leg pokes +0x37F once; the +0xB2 legs hold +0xB2 by a range poke; B4's readback leg plants 0x5A5A at +0x366
#   at f3200 (the field's positive control). A tap write in tap frame f lands in trace frame f+1.
# EXPECTS: the header names the ROM — every reference member verified against docs/checksums.txt, the vsavj program
#   fingerprint equal to the registry's vsavj row, each loaded zip's sha1 — or the gate FAILs before any leg; and it
#   names the MAME (tests/lib/mame_ident.sh), or the gate FAILs. Every leg complete and every tap live. F1-F7 (B3),
#   G1-G5 (B4), D1-D7 (+0xB2) as stated in WHAT. CONTROLS (in-gate, each must make its check fail): lock-unpoked (F5
#   judged on the unpoked Up leg), exit-swapped (F2 expecting the button exit's PC on the Up leg), p2-side (F2 and D2
#   judged on P2's +0x37F / +0xB2), headsit-blind (F1 judged on the crouching-Victor leg), countdown-shifted (F3 expecting 8..1),
#   row-swapped (G1 expecting the down redirect's write from 0x032E62), es-blind (G1 judging the LP air Beast Cannon as
#   row 1), readback-unpoked (G4 judged on the unplanted leg), hiword-dropped (G1 with the +0x364 word writes dropped
#   from the tap), decode-rotated (D4 with the value -> multiplier map rotated by one), poke-ignored (D4 judged with the
#   Dark Force leg in place of each poked leg), attribution-swapped (D3 expecting P1's read first), projectiles-halved (D8/D9 expecting the losses halved),
#   projectile-reads-p1 (D8/D9 expecting the scaler to read P1's +0xB2 before each projectile hit). The log's header
#   names the commit and host.
# RIG RECORDS (poke read-back READS-BACK, ruled 2026-10-31, 14z-215): p1_364 (the +0x366 plant's long) and c1b2 (the double's +0xB2 on the held legs) — sampled, never judged; a record of the rig's poke, never a measurement of the game.
# FOLLOWS: emu/mame-patches/ tests/lib/controls.sh tests/lib/mame_ident.sh tests/lib/decrypt_cache.sh tools/cps2_decrypt.py
#   tests/lua/field_trace.lua tests/lua/pokes_spec.lua
#   tests/lua/read_tap.lua tests/replays/df/105_df_sas_armor.rpl tools/anim_nodes.py tools/_minitoml.py
#   build/manifest/bank_map.toml tools/run_mame.sh tools/setup_mame.sh tools/audit_roms.py docs/checksums.txt
#   tools/build_fingerprint.py tests/expected/registry.tsv
#
# SHEET: none — measures pristine vsavj and/or native vsav2 only; no leg of our build
#
# MUST-FIRE: known-bad: lock-unpoked — F5 ("no headsit after the exit") judged on the unpoked Up leg, which sits again at f3129, must fail, so F5 sees the re-headsit the poke removes (in-gate; as a mode F5 judges the unpoked leg and the gate FAILs)
# MUST-FIRE: perturbed-copy: exit-swapped — F2 expecting PRG:0x0403EE (the button exit) on the Up leg must fail, so the three exits are told apart (in-gate; as a mode F2 expects it and the gate FAILs)
# MUST-FIRE: perturbed-copy: p2-side — F2 judged on P2's +0x37F and D2 on P2's +0xB2 must fail, so the taps see which side is which (in-gate; as a mode F2 and D2 judge P2 and the gate FAILs)
# MUST-FIRE: known-bad: headsit-blind — F1 judged on the crouching-Victor leg (the same jump, no headsit) must fail, so the headsit detector (state and chain) tells a headsit from a jump (in-gate; as a mode F1 judges that leg and the gate FAILs)
# MUST-FIRE: perturbed-copy: countdown-shifted — F3 expecting the countdown 8..1 instead of 7..0 must fail, so the values are read, not assumed (in-gate; as a mode F3 expects 8..1 and the gate FAILs)
# MUST-FIRE: perturbed-copy: row-swapped — G1 expecting the down redirect's write from PRG:0x032E62 instead of 0x032EC0 must fail, so the two table copies are told apart (in-gate; as a mode G1 expects it and the gate FAILs)
# MUST-FIRE: perturbed-copy: es-blind — G1 expecting +0x102 = 6 (row 1) on the LP air Beast Cannon must fail, so the row is measured (in-gate; as a mode G1 expects it and the gate FAILs)
# MUST-FIRE: known-bad: readback-unpoked — G4 judged on the unplanted air Beast Cannon leg must fail, so G4's 0x5A5A comes from the plant at +0x366's address (in-gate; as a mode G4 judges the unplanted leg and the gate FAILs)
# MUST-FIRE: perturbed-copy: hiword-dropped — G1 judged on a copy of the tap with every +0x364 word write dropped must fail, so the long's high word is seen written in the same frame as the zero low word (in-gate; as a mode G1 drops them and the gate FAILs)
# MUST-FIRE: perturbed-copy: decode-rotated — D4 with the value -> multiplier map rotated by one (0 x1.25, 2 x0.5, 4 x0.25, 6 x1) must fail, so each value's multiplier is measured (in-gate; as a mode D4 uses the rotated map and the gate FAILs)
# MUST-FIRE: known-bad: poke-ignored — D4 judged with the unpoked Dark Force leg in place of each poked leg must fail, so the poked +0xB2 is what changes the damage (in-gate; as a mode D4 judges the unpoked leg and the gate FAILs)
# MUST-FIRE: perturbed-copy: attribution-swapped — D3 expecting the scaler to read P1's +0xB2 before slot 1's must fail, so the first hit is the double's (in-gate; as a mode D3 expects P1 first and the gate FAILs)
# MUST-FIRE: perturbed-copy: projectiles-halved — D8 and D9 expecting each Dark Force projectile hit to lose the no-Dark-Force loss >> 1 must fail, so "unscaled" is measured against the no-Dark-Force legs (in-gate; as a mode they expect the halved losses and the gate FAILs)
# MUST-FIRE: perturbed-copy: projectile-reads-p1 — D8 and D9 expecting the scaler's reads before each projectile hit to name P1's +0xB2 (4) must fail, so the hit is attributed to the projectile slot whose +0xB2 is 0 (in-gate; as a mode they expect P1 and the gate FAILs)
#
# NOT COVERED: B3 — one spacing and one Victor; whether the lockout bites a fall that comes back within 8 ticks
#   without a poke (no natural arc does here); the 0x0403AA exit by the round's end or the 0x02706E path; other
#   directions of the 0x040450 exit than Up; the headsit against other opponents or a crouching one at other spacings.
#   B4 — Gallon's reads of +0x364 (S0: a clamp against +0x44) are not traced; why the community calls it a timer is not
#   judged; Morrigan's own +0x366 writer (PRG:0x038FEA, a timer per S0) is not reached by her forward dash, with or
#   without Up, and is not judged. +0xB2 — why Morrigan's second hit in a frame has base 10, not 11 (another reduction,
#   not +0xB2's); the engine clear PRG:0x026FCC (ids 0x08/0x18) and the writers 0x055D56, 0x0546C2 and 0x05C5EC are
#   not reached; the value 2 occurs only by poke (no static writer of 2, S0).
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] tests/audit_mizuumi_rows_c.sh
#   emulator tier, MAME; scope ondemand (the pristine-only ruling); ~2-3 min on the M2 Pro (70 legs, three at a time; then fourteen
#   control re-judgements of the same legs, ~25 s)
set -u
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"; export MAME_BIN
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$SELF"; MODE="${VS_CTL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no reference MAME binary at $MAME_BIN"; exit 0; }
romchk="$(python3 "$REPO/tools/audit_roms.py" "$ROMDIR" 2>&1)" || true
echo "$romchk" | grep >/dev/null 'all match' || { echo "FAIL: ROMDIR is not the pristine reference set (tools/audit_roms.py against docs/checksums.txt):"; echo "$romchk" | tail -5; exit 1; }
romfp="$(python3 "$REPO/tools/build_fingerprint.py" "$ROMDIR" --set vsavj --sha-only 2>/dev/null)" || true
regfp="$(awk -F'\t' '$2 == "vsavj" && $1 !~ /^#/ {print $1}' "$REPO/tests/expected/registry.tsv")"
[ -n "$romfp" ] && [ "$romfp" = "$regfp" ] || { echo "FAIL: vsavj program fingerprint '$romfp' is not the registry's vsavj row '$regfp'"; exit 1; }
echo "  rom   $(echo "$romchk" | grep 'all match' | head -1); vsavj program fingerprint $romfp = registry vsavj row; zips $(python3 -c 'import hashlib,sys; print(" ".join(f"{z}.zip=" + hashlib.sha1(open(f"{sys.argv[1]}/{z}.zip","rb").read()).hexdigest() for z in ("vsavj","vsav","qsound_hle")))' "$ROMDIR")"
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else
    W="$(mktemp -d)" || { echo "FAIL: audit_mizuumi_rows_c — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM; fi
W="$(cd "$W" && pwd)"
echo "  head  $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo no git); tracked files modified $(git -C "$REPO" status --porcelain --untracked-files=no 2>/dev/null | wc -l | tr -d ' '); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN"
. "$REPO/tests/lib/mame_ident.sh"; vs_mame_ident "$MAME_BIN" || { echo "FAIL: the MAME binary is not the pinned release (above)"; exit 1; }
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 || { echo "FAIL: audit_mizuumi_rows_c — the vsavj data view could not be made (tests/lib/decrypt_cache.sh)"; exit 1; }

# THE SCRIPTS: replay 105's select prologue (its first eight input lines), then each leg's lines.
RPL="$REPO/tests/replays/df/105_df_sas_armor.rpl"
grep -E '^[0-9]' "$RPL" | head -8 > "$W/prologue"
[ "$(wc -l < "$W/prologue" | tr -d ' ')" = 8 ] && grep -q '^1360-1362 p2=1$' "$W/prologue" || { echo "FAIL: replay 105's prologue is not the eight lines this gate was measured on"; exit 1; }
mk() {  # mk <name> <end frame> <lines, newline-separated>
    { cat "$W/prologue"; printf '%s\n' "$3"; echo "$2 wait"; } > "$W/$1.rpl"
}
J12="3000-3011 p1=R
3012-3014 p1=UR"
QCF() { printf '%s\n' "$1-$(($1+1)) p1=D" "$(($1+2))-$(($1+3)) p1=DR" "$(($1+4))-$(($1+8)) p1=R" "$(($1+5))-$(($1+9)) p1=$2"; }
DPM() { printf '%s\n' "$1-$(($1+2)) p1=R" "$(($1+4))-$(($1+6)) p1=D" "$(($1+8))-$(($1+11)) p1=DR$2"; }
# B3
mk hs_sit 3400 "$J12"
mk hs_p2 3400 "$J12
3100-3140 p2=D"
mk hs_btn 3400 "$J12
3100-3102 p1=1"
mk hs_up 3400 "$J12
3100-3104 p1=U"
mk crouch_p2 3400 "$J12
2990-3300 p2=D"
mk jump_far 3400 "3000-3002 p1=UR"
mk jump_over 3400 "3000-3023 p1=R
3024-3026 p1=UR"
mk hs_btn_jump 3400 "$J12
3100-3102 p1=1
3200-3202 p1=U"
# B4
mk g_idle 3300 "3000-3002 p1=1"
mk bc_lp 3300 "$(QCF 3000 1)"
mk bc_hp 3300 "$(QCF 3000 3)"
mk bc_es 3300 "$(QCF 3000 13)"
mk bc_up 3300 "$(QCF 3000 1)
3020-3023 p1=U1"
mk dbc_lp 3300 "$(DPM 3000 1)"
mk dbc_hp 3300 "$(DPM 3000 3)"
mk jbc_lp 3300 "3000-3002 p1=U
$(QCF 3012 1)"
mk jbc_es 3300 "3000-3002 p1=U
$(QCF 3012 13)"
mk jbc_rd 3300 "3000-3002 p1=U
$(QCF 3012 1)
3034-3037 p1=D1"
mk jbc_es_rd 3300 "3000-3002 p1=U
$(QCF 3012 13)
3034-3037 p1=D1"
# +0xB2
mk m_nodf 3600 "3000-3019 p1=R
3150-3152 p1=3
3300-3302 p1=3"
mk m_df 3600 "3000-3019 p1=R
3060-3063 p1=14
3150-3152 p1=3
3300-3302 p1=3"
SFI() { printf '%s\n' "$1-$(($1+1)) p1=D" "$(($1+2))-$(($1+3)) p1=DR" "$(($1+4))-$(($1+8)) p1=R" "$(($1+5))-$(($1+9)) p1=1"; }
FSI() { printf '%s\n' "$1-$(($1+1)) p1=2" "$(($1+3))-$(($1+4)) p1=1" "$(($1+6))-$(($1+7)) p1=L" "$(($1+9))-$(($1+10)) p1=4" "$(($1+12))-$(($1+13)) p1=5"; }
mk x_sf 3600 "3000-3019 p1=R
$(SFI 3150)
$(SFI 3300)"
mk x_sf_df 3600 "3000-3019 p1=R
3060-3063 p1=14
$(SFI 3150)
$(SFI 3300)"
mk x_fs 3600 "3000-3019 p1=R
$(FSI 3150)"
mk x_fs_df 3600 "3000-3019 p1=R
3060-3063 p1=14
$(FSI 3150)"
mk m_dfh 3600 "3000-3019 p1=R
3060-3063 p1=36
3150-3152 p1=3
3300-3302 p1=3"

pk() { echo "1400:ff8782:$1;1450:ff8782:$1;1500:ff8782:$1;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"; }
PF="$(pk 07)"; PG="$(pk 02);2960:ff8509:03;2970:ff8509:03"
PM="$(pk 05);3040:ff8509:03;3050:ff8509:03"; PL="$(pk 0e);3040:ff8509:03;3050:ff8509:03"
LOCK="3101:ff877f:40"            # B3's subject poke: +0x37F := 0x40 the frame after the Up exit (tap f3099, trace f3100)
PLANT="3200:ff8766:5a5a"         # G4's read-back plant at +0x366
B2() { echo ";3070-3600:ff84b2:$1"; }    # P1's +0xB2 held through the Dark Force
C2() { echo ";3090-3600:ff95b2:$1"; }    # the double's (projectile slot 1) +0xB2 held
FF="ff8404:l:p1st,ff8410:w:p1x,ff8414:w:p1y,ff8810:w:p2x,ff8804:l:p2st,ff877f:b:p1_37f,ff8b7f:b:p2_37f,ff841c:l:p1an"
FG="ff8404:l:p1st,ff8764:l:p1_364,ff8766:w:p1_366,ff8502:b:p1_102,ff8b66:w:p2_366"
FM="ff802e:b:df,ff84b2:b:p1b2,ff88b2:b:p2b2,ff95b2:b:c1b2,ff9502:b:c1t,ff8850:w:p2hp"
FX="ff84b2:b:p1b2,ff8850:w:p2hp"; TX="ff84b2,2;ff8850,2"
i=0; while [ "$i" -lt 32 ]; do a=$((0xff9400 + i * 0x100)); FX="$FX,$(printf '%06x' $((a + 2))):b:t$i,$(printf '%06x' $((a + 0xb2))):b:b$i"; TX="$TX;$(printf '%06x' $((a + 0xb2))),2"; i=$((i + 1)); done
TF="ff877e,2;ff8b7e,2"; TG="ff8764,4;ff8b64,4"; TM="ff84b2,2;ff88b2,2;ff8850,2;ff95b2,2"
# leg table: name script pokes fields tap-ranges frames
LEGS="hs_sit|hs_sit|$PF|$FF|$TF|3400
hs_p2|hs_p2|$PF|$FF|$TF|3400
hs_btn|hs_btn|$PF|$FF|$TF|3400
hs_up|hs_up|$PF|$FF|$TF|3400
hs_uplock|hs_up|$PF;$LOCK|$FF|$TF|3400
crouch_p2|crouch_p2|$PF|$FF|$TF|3400
jump_far|jump_far|$PF|$FF|$TF|3400
jump_over|jump_over|$PF|$FF|$TF|3400
hs_btn_jump|hs_btn_jump|$PF|$FF|$TF|3400
g_idle|g_idle|$PG|$FG|$TG|3300
bc_lp|bc_lp|$PG|$FG|$TG|3300
bc_hp|bc_hp|$PG|$FG|$TG|3300
bc_es|bc_es|$PG|$FG|$TG|3300
bc_up|bc_up|$PG|$FG|$TG|3300
dbc_lp|dbc_lp|$PG|$FG|$TG|3300
dbc_hp|dbc_hp|$PG|$FG|$TG|3300
jbc_lp|jbc_lp|$PG|$FG|$TG|3300
jbc_es|jbc_es|$PG|$FG|$TG|3300
jbc_rd|jbc_rd|$PG|$FG|$TG|3300
jbc_es_rd|jbc_es_rd|$PG|$FG|$TG|3300
m_nodf|m_nodf|$PM|$FM|$TM|3600
m_df|m_df|$PM|$FM|$TM|3600
m_dfp0|m_df|$PM$(B2 00)|$FM|$TM|3600
m_dfp2|m_df|$PM$(B2 02)|$FM|$TM|3600
m_dfp6|m_df|$PM$(B2 06)|$FM|$TM|3600
m_dfc0|m_df|$PM$(C2 00)|$FM|$TM|3600
m_dfboth0|m_df|$PM$(B2 00)$(C2 00)|$FM|$TM|3600
m_nodfp4|m_nodf|$PM$(B2 04)|$FM|$TM|3600
l_df|m_df|$PL|$FM|$TM|3600
l_dfh|m_dfh|$PL|$FM|$TM|3600"
run1() {  # run1 field|tap|read <name> <script> <pokes> <spec> <frames>
    d="$W/$2.$1"; rm -rf "$d"; mkdir -p "$d"
    case "$1" in
    field) ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$W/$3.rpl" POKES="$4" FIELDS="$5" FIELD_OUT="$d/out.txt" \
               FIELD_FROM=2990 FRAMES="$6" timeout -k 30 900 "$REPO/tools/run_mame.sh" vsavj \
               -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) ;;
    tap)   ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$W/$3.rpl" POKES="$4" RTAP="$5" WINDOW="0,0" \
               TRACE_OUT="$d/out.txt" FRAMES="$6" timeout -k 30 900 "$REPO/tools/run_mame.sh" vsavj \
               -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) ;;
    xread) ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$W/$3.rpl" POKES="$4" RTAP="$5" WINDOW="3100,3600" \
               RPCS=18bd4 TRACE_OUT="$d/out.txt" FRAMES="$6" timeout -k 30 900 "$REPO/tools/run_mame.sh" vsavj \
               -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) ;;
    read)  ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$W/$3.rpl" POKES="$4" RTAP="$5" WINDOW="3100,3400" \
               RPCS=18bd4 TRACE_OUT="$d/out.txt" FRAMES="$6" timeout -k 30 900 "$REPO/tools/run_mame.sh" vsavj \
               -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) ;;
    esac
}
echo "== 1. the legs (pristine vsavj, MAME, three at a time)"
JOBS="$(echo "$LEGS" | awk -F'|' '{print "field|" $0; print "tap|" $0}')
field|g_plant|jbc_lp|$PG;$PLANT|$FG|-|3300
read|m_read|m_df|$PM|-|$TM|3600
field|x_sf|x_sf|$PM|$FX|-|3600
xread|x_sf|x_sf|$PM|-|$TX|3600
field|x_sf_df|x_sf_df|$PM|$FX|-|3600
xread|x_sf_df|x_sf_df|$PM|-|$TX|3600
field|x_fs|x_fs|$PM|$FX|-|3600
xread|x_fs|x_fs|$PM|-|$TX|3600
field|x_fs_df|x_fs_df|$PM|$FX|-|3600
xread|x_fs_df|x_fs_df|$PM|-|$TX|3600"
n=0
echo "$JOBS" > "$W/jobs"
if [ "${REUSE:-}" = 1 ] && [ -n "${KEEP:-}" ]; then echo "  (REUSE=1: the control run re-judges the legs already in $W)"; else
while IFS='|' read -r kind name scr pks fld tap fr; do
    case "$kind" in field) spec="$fld" ;; *) spec="$tap" ;; esac
    run1 "$kind" "$name" "$scr" "$pks" "$spec" "$fr" </dev/null &
    n=$((n + 1)); [ $((n % 3)) = 0 ] && wait
done < "$W/jobs"
wait; fi
fail=0
while IFS='|' read -r kind name scr pks fld tap fr; do
    case "$kind" in
    field) grep -q '^FIELDSUMMARY' "$W/$name.field/out.txt" 2>/dev/null || { echo "  FAIL  $name field: no FIELDSUMMARY (see $W/$name.field/mame.log) — VOID"; fail=1; } ;;
    *)     grep -q '^END ' "$W/$name.$kind/out.txt" 2>/dev/null || { echo "  FAIL  $name $kind: no END line (see $W/$name.$kind/mame.log) — VOID"; fail=1; } ;;
    esac
done < "$W/jobs"
[ "$fail" = 0 ] || { echo "FAIL: audit_mizuumi_rows_c (a leg did not complete)"; exit 1; }
echo "  ok    $(wc -l < "$W/jobs" | tr -d ' ') legs complete"

echo "== 2. the checks"
python3 - "$W" "$MODE" "$REPO" <<'PY'
import sys
W, mode, REPO = sys.argv[1], sys.argv[2], sys.argv[3]
sys.path.insert(0, f"{REPO}/tools")
import _minitoml as mt
from anim_nodes import walk_table
def fields(n):
    out = {}
    for l in open(f"{W}/{n}.field/out.txt"):
        if l.startswith("F "):
            p = l.split(); out[int(p[1])] = {k: int(v) for k, v in (x.split("=") for x in p[2:])}
    return out
def tap(n, kind="tap"):
    w = []
    for l in open(f"{W}/{n}.{kind}/out.txt"):
        p = l.split()
        if p and p[0] in ("W", "R"):   # W|R <frame> PC <pc> off <addr> data <val> mask <m>
            w.append((p[0], int(p[1]), int(p[3], 16), int(p[5], 16), int(p[7], 16), int(p[9], 16)))
    return w
bad = []
def say(ok, msg):
    print(("  ok    " if ok else "  FAIL  ") + msg)
    if not ok: bad.append(msg)
B3 = ("hs_sit", "hs_p2", "hs_btn", "hs_up", "hs_uplock", "crouch_p2", "jump_far", "jump_over", "hs_btn_jump")
B4 = ("g_idle", "bc_lp", "bc_hp", "bc_es", "bc_up", "dbc_lp", "dbc_hp", "jbc_lp", "jbc_es", "jbc_rd", "jbc_es_rd")
BB = ("m_nodf", "m_df", "m_dfp0", "m_dfp2", "m_dfp6", "m_dfc0", "m_dfboth0", "m_nodfp4", "l_df", "l_dfh")
F = {n: fields(n) for n in B3 + B4 + BB + ("g_plant",)}
T = {n: tap(n) for n in B3 + B4 + BB}
for n, w in T.items():
    if not any(f < 1000 for _, f, *_ in w): say(False, f"tap {n}: dead (no write before f1000)")
say(all(any(f < 1000 for _, f, *_ in w) for w in T.values()), f"taps live: {len(T)} taps each log the boot writes before f1000")

# ---- B3: Felicia's +0x37F
bank = mt.loads(open(f"{REPO}/build/manifest/bank_map.toml").read())
rows = {t["name"]: int(t["vsavj"]) for t in bank["table"]}
import os
dv = f"{W}/vsavj_data.bin"   # the data view, delivered by tests/lib/decrypt_cache.sh above
if not os.path.exists(dv):
    print("  FAIL  no data view (tests/lib/decrypt_cache.sh)"); sys.exit(1)
img = open(dv, "rb").read()
def chains(cid, tabname):
    tab = int.from_bytes(img[rows[tabname] + cid * 4: rows[tabname] + cid * 4 + 4], "big")
    out = {}
    for seq, ch in walk_table(img, 0, tab)["chains"].items():
        for nd in ch["nodes"]:
            a = int(nd["addr"], 16) if isinstance(nd["addr"], str) else nd["addr"]
            out.setdefault(a, set()).add(int(str(seq), 0))
    return out
A2 = chains(7, "anim_index_a2")
HS_NODES = {a for a, s in A2.items() if 0x5A in s}
def headsit_frames(fl):
    return [f for f in sorted(fl) if (fl[f]["p1st"] & 0xFFFFFF00) == 0x02000E00 and (fl[f]["p1an"] & 0xFFFFFF) in HS_NODES]
def w37f(n, addr=0xFF877E):
    return [(f, pc, d & 0xFF) for k, f, pc, a, d, m in T[n] if k == "W" and f >= 2900 and a == addr and m & 0xFF]
f1leg = "crouch_p2" if mode == "headsit-blind" else "hs_sit"
hs = headsit_frames(F[f1leg])
say(bool(hs) and hs[0] == 3036 and hs[-1] == 3400 and not w37f(f1leg),
    f"F1 {f1leg}: headsit (state 0x02000E0x, chain a2:0x5a) from f{hs[0] if hs else None} to f{hs[-1] if hs else None}, {len(w37f(f1leg))} in-match +0x37F writes")
EXIT = {"hs_p2": 0x0403AA, "hs_btn": 0x0403EE, "hs_up": 0x040450}
if mode == "exit-swapped": EXIT["hs_up"] = 0x0403EE
addr2 = 0xFF8B7E if mode == "p2-side" else 0xFF877E
for n, pc in EXIT.items():
    w = w37f(n, addr2); fl = F[n]
    ok = bool(w) and w[0][1:] == (pc, 8) and (fl[w[0][0]]["p1st"] & 0xFFFFFF00) == 0x02000E00
    say(ok, f"F2 {n}: first in-match +0x37F write {[(f, hex(p), v) for f, p, v in w[:1]]} is 8 from {pc:#08x}, written in the headsit")
want3 = list(range(8, 0, -1)) if mode == "countdown-shifted" else list(range(7, -1, -1))
for n in ("hs_p2", "hs_up"):
    w = w37f(n)[1:]
    ok = [v for _, _, v in w] == want3 and all(pc == 0x03F3D2 for _, pc, _ in w) and all(F[n][f + 1]["p1st"] == 0x02000602 for f, _, _ in w)
    say(ok, f"F3 {n}: then {len(w)} writes from 0x03F3D2, values {[v for _, _, v in w]}, all in state 0x02000602 (want {want3})")
w = w37f("hs_btn"); fl = F["hs_btn"]
land = next(f for f in sorted(fl) if f > 3100 and fl[f]["p1st"] == 0x02000002)
say(len(w) == 1 and all(fl[f]["p1_37f"] == 8 for f in fl if 3100 <= f <= 3400) and fl[3100]["p1st"] == 0x02000606,
    f"F3 hs_btn: one write (8); +0x37F stays 8 through the 0x02000606 exit and the landing (standing f{land}) to f3400")
w = w37f("hs_btn_jump")
say([v for _, _, v in w] == [8] + want3 and all(f >= 3200 and pc == 0x03F3D2 for f, pc, _ in w[1:]),
    f"F3 hs_btn_jump: 8 at f{w[0][0]}, then the countdown only in the next jump: {[(f, v) for f, _, v in w[1:]][:3]}..")
re_up = [f for f in headsit_frames(F["hs_up"]) if f > 3100]
say(bool(re_up) and re_up[0] == 3129 and F["hs_up"][re_up[0]]["p1_37f"] == 0, f"F4 hs_up: sits again at f{re_up[0] if re_up else None} with +0x37F 0")
f5 = "hs_up" if mode == "lock-unpoked" else "hs_uplock"
re_lk = [f for f in headsit_frames(F[f5]) if f > 3100]; fl = F[f5]
say(not re_lk and fl[3101]["p1_37f"] == 0x40 and fl[3129]["p1_37f"] > 0,
    f"F5 {f5}: +0x37F {fl[3101]['p1_37f']} at f3101, {fl[3129]['p1_37f']} at f3129; headsit frames after the exit: {len(re_lk)}")
for n in ("crouch_p2", "jump_far", "jump_over"):
    say(not headsit_frames(F[n]) and not w37f(n), f"F6 {n}: no headsit frame, {len(w37f(n))} in-match +0x37F writes")
p2w = [x for n in B3 for x in w37f(n, 0xFF8B7E)]
say(not p2w, f"F7 P2's +0x37F: {len(p2w)} in-match writes over {len(B3)} taps")

# ---- B4: Gallon's +0x364 long / +0x366
def g_w(n, base=0xFF8764):
    w = [(f, pc, a, d & 0xFFFF) for k, f, pc, a, d, m in T[n] if k == "W" and f >= 2900 and a in (base, base + 2)]
    if mode == "hiword-dropped": w = [x for x in w if x[2] != base]
    return w
ROWS = {"jbc_lp": [(0x032E62, False)], "jbc_es": [(0x032E62, True)], "jbc_rd": [(0x032E62, False), (0x032EC0, False)],
        "jbc_es_rd": [(0x032E62, True), (0x032EC0, True)]}
if mode == "row-swapped": ROWS["jbc_rd"] = [(0x032E62, False), (0x032E62, False)]
if mode == "es-blind": ROWS["jbc_lp"] = [(0x032E62, True)]
for n, want in ROWS.items():
    w = g_w(n); fr = sorted({f for f, *_ in w}); got = []
    for f in fr:
        ws = [x for x in w if x[0] == f]
        hi = [d for _, _, a, d in ws if a == 0xFF8764]; lo = [d for _, _, a, d in ws if a == 0xFF8766]
        pcs = {pc for _, pc, _, _ in ws}
        got.append((pcs.pop() if len(pcs) == 1 else None, F[n][f + 1]["p1_102"] == 6, hi == [hi[0]] and hi[0] != 0 if hi else False, lo == [0]))
    ok = [(pc, es) for pc, es, _, _ in got] == want and all(h and l for _, _, h, l in got)
    say(ok, f"G1 {n}: +0x364 writes at f{fr}: (PC, +0x102==6, high word non-zero, +0x366 = 0) {[(hex(p) if p else p, e, h, l) for p, e, h, l in got]}")
for n in ("g_idle", "bc_lp", "bc_hp", "bc_es", "bc_up", "dbc_lp", "dbc_hp"):
    say(not g_w(n), f"G2 {n}: {len(g_w(n))} in-match writes of +0x364..+0x367")
nz = [n for n in B4 if any(v["p1_366"] for f, v in F[n].items() if f >= 2990)]
say(not nz, f"G3 field: +0x366 0 on every frame f2990+ of {len(B4)} Gallon legs (non-zero on: {nz})")
g4 = F["jbc_lp" if mode == "readback-unpoked" else "g_plant"]
say(all(v["p1_366"] == 0x5A5A for f, v in g4.items() if f >= 3200) and all(v["p1_366"] == 0 for f, v in g4.items() if f < 3200),
    "G4 readback: 0x5A5A planted at +0x366 at f3200 reads back on every later frame, 0 before")
p2g = [x for n in B4 for x in g_w(n, 0xFF8B64)]
say(not p2g, f"G5 P2's +0x364..+0x367: {len(p2g)} in-match writes over {len(B4)} taps")

# ---- +0xB2: the damage scaler
def hp(n):   # P2 HP losses, one per write by the damage routine, in order: (frame, loss)
    out, prev = [], 288
    for k, f, pc, a, d, m in T[n]:
        if k == "W" and f >= 3100 and a == 0xFF8850:
            out.append((f, pc, prev - d)); prev = d
    return out
def b2w(n, a):
    return [(f, pc, (d >> 8) & 0xFF) for k, f, pc, aa, d, m in T[n] if k == "W" and f >= 2990 and aa == a and m & 0xFF00 and pc >= 0x2000]
h = hp("m_nodf")
say([(f, pc, x) for f, pc, x in h] == [(3156, 0x018AC0, 11)] and not b2w("m_nodf", 0xFF84B2), f"D1 m_nodf: HP losses {[(f, hex(pc), x) for f, pc, x in h]}; P1 +0xB2 in-match writes {b2w('m_nodf', 0xFF84B2)}")
d2a = 0xFF88B2 if mode == "p2-side" else 0xFF84B2
w1, wc = b2w("m_df", d2a), b2w("m_df", 0xFF95B2)
say(w1 == [(3059, 0x039AAC, 4), (3356, 0x039A84, 0)] and wc == [(3086, 0x056D28, 4)] and [x for _, _, x in hp("m_df")] == [5, 5, 5, 5],
    f"D2 m_df: +0xB2 writes P1 {[(f, hex(p), v) for f, p, v in w1]}, slot 1 {[(f, hex(p), v) for f, p, v in wc]}; HP losses {[(f, x) for f, _, x in hp('m_df')]}")
rd = [(f, a) for k, f, pc, a, d, m in tap("m_read", "read") if k == "R" and pc == 0x018BD4]
order = [a for f, a in rd if f == 3156]
wantorder = [0xFF84B2, 0xFF84B2, 0xFF95B2, 0xFF95B2] if mode == "attribution-swapped" else [0xFF95B2, 0xFF95B2, 0xFF84B2, 0xFF84B2]
say(order == wantorder and [a for f, a in rd if f == 3305] == [0xFF95B2, 0xFF95B2, 0xFF84B2, 0xFF84B2],
    f"D3 m_read: PC 0x018BD4 reads at f3156 {[hex(a) for a in order]} (slot 1's +0xB2 twice, then P1's twice); f3305 the same")
MUL = {0: lambda d: d, 2: lambda d: d + (d >> 2), 4: lambda d: d >> 1, 6: lambda d: d >> 2}
if mode == "decode-rotated": MUL = {0: MUL[2], 2: MUL[4], 4: MUL[6], 6: MUL[0]}
legs4 = {0: "m_dfp0", 2: "m_dfp2", 4: "m_df", 6: "m_dfp6"}
if mode == "poke-ignored": legs4 = {k: "m_df" for k in legs4}
base = hp("m_dfp0")[1][2]
got4 = {v: [x for _, _, x in hp(n)][1::2] for v, n in legs4.items()}
say(base == 10 and all(got4[v] == [MUL[v](base)] * 2 for v in got4),
    f"D4 Morrigan's hit (each frame's 2nd loss) with her +0xB2 held at 0/2/4/6: {got4} = x1, x1.25, x0.5, x0.25 of {base}")
d5 = {n: [x for _, _, x in hp(n)] for n in ("m_df", "m_dfc0", "m_dfboth0")}
say(d5 == {"m_df": [5, 5, 5, 5], "m_dfc0": [11, 5, 11, 5], "m_dfboth0": [11, 10, 11, 10]}, f"D5 the double's hit (1st loss): {d5}")
say([x for _, _, x in hp("m_nodfp4")] == [11 >> 1], f"D6 m_nodfp4 (no Dark Force, P1 +0xB2 held 4): HP losses {[x for _, _, x in hp('m_nodfp4')]} (11 >> 1 = 5)")
lh, lc = b2w("l_dfh", 0xFF84B2), b2w("l_dfh", 0xFF95B2)
say(lh[:1] == [(3059, 0x04DFF8, 4)] and lc == [(3086, 0x05CA5C, 4)] and [x for _, _, x in hp("l_dfh")] == [5, 5, 5, 5],
    f"D7 l_dfh (Lilith HP+HK): P1 {[(f, hex(p), v) for f, p, v in lh]}, slot 1 {[(f, hex(p), v) for f, p, v in lc]}, HP {[x for _, _, x in hp('l_dfh')]}")
ll, llc = b2w("l_df", 0xFF84B2), b2w("l_df", 0xFF95B2)
say(all(v == 0 for _, _, v in ll) and llc == [(3086, 0x05CD26, 6)] and [x for _, _, x in hp("l_df")] == [11],
    f"D7 l_df (Lilith LP+LK): P1 non-zero +0xB2 writes {[x for x in ll if x[2]]}, slot 1 {[(f, hex(p), v) for f, p, v in llc]}, HP {[x for _, _, x in hp('l_df')]}")
# ---- the projectiles: Soul Fist and Finishing Shower (the maintainer's exception)
def hits(n):
    """each HP write from f3100 in tap order: (frame, loss, [(reader, +0xB2 read)], {slot: type at the frame})"""
    fl = fields(n); out, prev, rd = [], 288, []
    for k, f, pc, a, d, m in tap(n, "xread"):
        if f < 3100: continue
        if k == "R" and pc == 0x018BD4:
            rd.append(("P1" if a == 0xFF84B2 else (a - 0xFF94B2) // 0x100, (d >> 8) & 0xFF))
        elif k == "W" and a == 0xFF8850:
            out.append((f, prev - d, rd, {r: fl[f + 1][f"t{r}"] for r, _ in rd if r != "P1"})); prev = d; rd = []
    return out, fl
def spawns(n):
    return {((a - 0xFF94B2) // 0x100) for k, f, pc, a, d, m in tap(n, "xread") if k == "W" and f >= 3100 and pc == 0x0546C2 and 0xFF94B2 <= a < 0xFF9400 + 0x2000 and m & 0xFF00 and (d >> 8) & 0xFF == 0}
def proj_ok(h, typ):  # every read before the hit names one projectile slot of this type, reading 0, twice
    if mode == "projectile-reads-p1": return all(r == [("P1", 4), ("P1", 4)] for _, _, r, _ in h)
    return all(len(r) == 2 and r[0] == r[1] and r[0][0] != "P1" and r[0][1] == 0 and t.get(r[0][0]) == typ for _, _, r, t in h)
hs, _ = hits("x_sf"); hd, fd = hits("x_sf_df")
want_d = [10, 9, 10, 9]
if mode == "projectiles-halved": want_d = [x >> 1 for x in (10, 10, 10, 10)]
p1_4 = all(fd[f + 1]["p1b2"] == 4 for f, _, _, _ in hd)
say([x for _, x, _, _ in hs] == [10, 10] and proj_ok(hs, 0x0B) and [x for _, x, _, _ in hd] == want_d and proj_ok(hd, 0x0B) and p1_4
    and len({r[0][0] for _, _, r, _ in hd[:2]}) == 2,
    f"D8 Soul Fist: without DF {[(f, x, r[0]) for f, x, r, _ in hs]}; in DF {[(f, x, r[0]) for f, x, r, _ in hd]} (two type-0x0B slots, each +0xB2 0 from 0x0546C2: {sorted(spawns('x_sf_df'))}); P1 +0xB2 4 at every DF hit: {p1_4}")
fs, _ = hits("x_fs"); fsd, ffd = hits("x_fs_df")
ms = [h for h in fs if h[0] >= 3180]; msd = [h for h in fsd if h[0] >= 3180]
w5 = [x >> 1 for _, x, _, _ in ms[:5]] if mode == "projectiles-halved" else [x for _, x, _, _ in ms[:5]]
say(len(ms) == 15 and len(msd) == 27 and proj_ok(ms, 0x0D) and proj_ok(msd, 0x0D) and [x for _, x, _, _ in msd[:5]] == w5 == ([3, 3, 3, 2, 2] if not mode else w5)
    and all(ffd[f + 1]["p1b2"] == 4 for f, _, _, _ in msd),
    f"D9 Finishing Shower missiles: without DF {len(ms)} hits {[x for _, x, _, _ in ms]}; in DF {len(msd)} hits {[x for _, x, _, _ in msd]}; every hit read a type-0x0D slot's +0xB2 = 0 while P1's was 4")
mp, mpd = [h for h in fs if h[0] < 3180], [h for h in fsd if h[0] < 3180]
print(f"  info  the Finishing Shower input's first button (MP) lands a normal first: without DF {[(f, x, r[0]) for f, x, r, _ in mp]}; in DF {[(f, x, r[0]) for f, x, r, _ in mpd]} (scaled by the double's and P1's +0xB2 4)")
sys.exit(1 if bad else 0)
PY
rc=$?
[ "$rc" = 0 ] || { echo "FAIL: audit_mizuumi_rows_c"; exit 1; }
if [ -z "$MODE" ]; then
    # THE CONTROLS: each declared mode re-runs the checks on the SAME legs (no new MAME run) and must FAIL
    for c in lock-unpoked exit-swapped p2-side headsit-blind countdown-shifted row-swapped es-blind readback-unpoked \
             hiword-dropped decode-rotated poke-ignored attribution-swapped projectiles-halved projectile-reads-p1; do
        CONTROL="$c" KEEP="$W" REUSE=1 sh "$SELF" > "$W/ctl_$c.log" 2>&1; crc=$?
        nf="$(grep -cE '^  FAIL  [FGD][0-9]' "$W/ctl_$c.log")"
        if [ "$crc" != 0 ] && grep -q "^CONTROL MODE: $c" "$W/ctl_$c.log" && [ "$nf" -gt 0 ]; then
            vs_ctl_fired "$c" "the mode run FAILs at $(grep -E '^  FAIL  [FGD][0-9]' "$W/ctl_$c.log" | cut -c9-11 | sort -u | tr '\n' ' ')($nf check line(s))"
        else vs_ctl_dead "$c" "the mode run exited $crc with $nf failed check line(s) (see $W/ctl_$c.log)"; rc=1; fi
    done
fi
[ "$rc" = 0 ] || { echo "FAIL: audit_mizuumi_rows_c (a control is dead)"; exit 1; }
echo "PASS: audit_mizuumi_rows_c — +0x37F is Felicia's 8-tick headsit lockout set at the three exits; +0x366 is the zero low word of Gallon's +0x364 long; +0xB2 selects x1/x1.25/x0.5/x0.25, 4 in Morrigan's and Lilith's mirror Dark Forces"
