# Capture sheet notes — what each sheet's gate is for, and what it does not cover

**STATUS: live since 14z-205 (2026-10-18, #291; the maintainer: *"Such an explanation would be a great addition to all
other capture sheets"*).** One `## <gate>` section per gate, read by `tools/proof_sheets.py page`, which shows a gate's
section above its pictures; a gate with no section shows none. A section says, in plain words, WHY the gate compares
the legs it compares and WHAT a reader of the pictures might expect it to check that it does NOT. The facts stay in the
gate's header and the subject documents; a section names a ticket by its number and never restates its status.
`tests/test_proof_sheets.sh` holds the rendering and refuses a section whose gate does not exist.

Format: paragraphs, `- ` bullets, `**bold**`, `` `code` `` and `#N` (rendered as a link to the issue).

## audit_air_dash_height

**Why the gate looks the way it does.** It was built for #222: on vs2 Phobos's air dash has a minimum height of 24,
and ours allowed it at height 21. It was ruled that Phobos, a vs2-only character, follows vs2 for his air dash, and
since the M23 build ours takes vs2's mask bit and table row. The rig makes Phobos jump straight up and input the air
dash with the second forward press at +5 to +16 frames. At +5, height 21, neither game dashes; at every later event,
height 34 and up, both dash on the same frame at the same height. So on the low event both pictures show no dash.

**What isn't covered.**
- Only heights 21 and then 34 and up are sampled; heights in between are not tested.
- Straight-up jumps only, with the second forward press at +5 to +16 frames.
- Pinned level and random number; MAME only; the build the gate is given (`BUILD`).

## audit_air_gc_legacy

**Why the gate looks the way it does.** The legacy control for #182, where Phobos's guard cancel from an air block never fires on ours: before fixing it, the gate shows the air guard cancel is Phobos's alone in both games, so a fix overrides no rule of the host engine, and it is the legacy guard any fix must keep green. Lei-Lei and Zabel try their guard cancel against Demitri from a ground block and from two air blocks, on pristine vsavj, native vs2 and ours, and the three legs must give the same rows. Native Phobos on vs2 is the positive leg: on the same timings he does commit an air guard cancel, so the legacy zero is a zero at a timing that can produce one. Lei-Lei's 623+P does come out of an air block, with no guard cancel banner, identically on every leg; it is not a guard cancel.

**What isn't covered.**
- The other original characters: their air block was read in the code of both games, not played.
- P2 as the character, the left side, and any timing other than the three events.
- Phobos himself on ours against native: that is `audit_chains174`.
- Level 6 and the RNG are pinned; MAME only, not FBNeo.

## audit_chains174

**Why the gate looks the way it does.** #174 counted the tenants' attack chains that no naming rig had ever entered;
eight of them carry attack records, and this gate covers those eight. They are Phobos's Reflect Wall from a crouching
and from an air block, his Genocide Vulcan (ES) catching a jump-in, Donovan's ES pursuit after Sword Grapple, Pyron's
Piled Hell with three kicks, and his 6MP and 6HP at range. Each rig is first proven to enter its chain on native vs2,
then ours is compared against native event by event. The rig sets position, stock and P2's HP at fixed frames, so each
event after such a pin starts from the rig's shared position by design, not from natural play.

**What isn't covered.**
- The other 28 never-entered a2 starts, which have no attack record, and the never-entered chains of tables a, b and
  c.
- P2 as the tenant; the ES pursuit's KKK and PP inputs, and Sword Grapple with MP.
- A random path other than zero: the random number is pinned at 0000, where every draw returns 0 (#183).
- A DIFF verdict reports only the first difference in its window.
- MAME only; level 6 pinned; the build the gate is given.

## audit_chains184

**Why the gate looks the way it does.** #184 is about the tenants' animation chains with no attack record that no rig
had ever entered, so their ours-against-native match was never measured. This gate takes the ten that a focused rig
enters on native vs2, such as Donovan's Start-button taunt, Phobos's Circuit Scrapper whiff and Pyron's taunt. Each rig
is first proven to enter its chain on native, then ours is compared with native event by event. Entry is read from a
third, native-only run, and landing on a chain's first node is not entering it. Each event's outcome is also checked
on native (hit and contact events damage P2; blocks, misses, whiffs and taunts do not), so a whiff cannot pass for a hit.

**What isn't covered.**
- Every entry and verdict holds at the parity gates' pins only: level 6 from frame 2000 and the RNG held at 0000; with
  another RNG value the Sword Grapple whiff no longer starts its chain on native.
- The other 21 chains: answered in `docs/game/engine_internals.md`, not compared here.
- P2 as the tenant; FBNeo.
- The chains' boxes and properties beyond what `tools/move_parity.py` compares.
- The grab whiffs at timings other than the rig's (#168).

## audit_column_flash

**Why the gate looks the way it does.** As Donovan's Killshread Lightning column ends, the maintainer saw the
stand-like entity above him turn orange instead of staying blue, and ruled "Ticket it, go on". Both games use the same
palettes in their sprite lists; the difference is the content of palette row 11. Ours holds a fire ramp there where
native vs2 keeps its blue ramp, and the extra upload at frame 2858 is ours alone. The gate compares ours against native
vs2 at 2858 (before the swap), 2860 and 2866 (after): native's row must stay the same and ours must equal native at
2858, so a leg that missed the move cannot pass. The flash is frozen as measured, so a fix of the flash turns this gate
red.

**What isn't covered.**
- Which sequence our build uploads at 2807 and 2858, and why: the ticket's open question.
- Other palette rows; row 11 is compared as a hash, never its bytes.
- One rig (the naming part `donovan_4`) with the speed-level and RNG pins.
- MAME only: FBNeo and the MiSTer core are not covered.

## audit_column_flash_cause

**Why the gate looks the way it does.** #162: the deity above Donovan flashes orange as his Killshread Lightning column
ends. Earlier work found the row (11), its writer and its source (his palette block row 1), but not which path sends it
there; `audit_column_flash` freezes the symptom, and this gate freezes the path. When Donovan's palette is reloaded, a
per-character mask decides whether rows 1-3 are reloaded too: vs2's mask has Donovan's bit, so native reloads row 0
only; ours keeps vsavj's mask, without his bit, so it reloads rows 1-3 and the orange ramp lands in row 11. A third leg
sets that bit in the emulator's copy of the program only, and the row-11 write goes away; a static census lists every
such mask site where a tenant's bit differs. The pictures: the reloads at 2807 (the move's start) and 2858 (its end).

**What isn't covered.**
- How the flash looks with the bit set: there is no capture of it.
- Row 11 before the move (ours holds the orange row from the match-start load, native another): not frozen here.
- What the census's other differing sites do in play (static only).
- FBNeo and the MiSTer core.
- Each game's stage, the palette rows other than 0x0A-0x0D, and P2's art (each game's own copy).

## audit_column_shock

**Why the gate looks the way it does.** In the #136 parity work, Donovan's Killshread Lightning column played differently on ours. On native vs2 its hits shock the victim 24 frames and leave Donovan unfrozen; on ours an old remap gave them the Lightning Sword's values, 12 frames and Donovan frozen 4. Since the 14z-170 fix the gate checks that every shock and freeze write of both fighters equals native's in frame and value, the move's timeline matches, and a column KO takes the same path. Since 14z-181 it also checks the column on a jumping victim, which takes the air case (class 7) on both legs. The pictures are frames of the move's timeline, the KO's death frame and the first airborne hit, each leg on its own frames; Demitri is each game's own art.

**What isn't covered.**
- The shock and freeze writes themselves are not drawn; the pictures show the hit frames from the timeline.
- One rig, `donovan_4` (the MP column at 2800), with writes read over frames 2836-2852 only.
- The Plasma Trap, the same class of remap, is checked by `audit_trap_shock`, not here.
- MAME only, real cursor picks with the parity gate's pins.

## audit_continue_ladder

**Why the gate looks the way it does.** It was built for #102: later arcade matches land on earlier venues and the
chain can exceed the arcade norm, when switching to or from VS2 characters. To tell whether that is ours, the gate
runs a full arcade marathon with a legacy character, Victor, on pristine vsavj and on our build. On both, a loss
followed by a continue clears the ladder's in-use venue mask, so the venue pool restarts: earlier venues and extra
matches are the engine's own behaviour, not a port defect. The vsavj leg is the point: if it ever stops showing the
reset, the behaviour was ours after all. The pictures show the reset on each leg, but on different frames and after
different matches, because the venue drawn and the match lost are lottery draws that differ between builds.

**What isn't covered.**
- The path is not compared: only the shape of the reset is checked, not which venues come in which order.
- A check that the mask builds up again after a continue was removed, because a dump every 80 frames does not reliably
  catch it.
- The VS2 characters themselves are not run: the gate uses a legacy character by design.
- Victor only; MAME only; natural losses, with no kill pokes.

## audit_crouch_flag

**Why the gate looks the way it does.** The game's guard decision checks the victim's +0x121 before choosing between two lists of attack classes, one for a standing victim and one for a crouching one. Which list was which rested on what +0x121 is, and that was undocumented until this gate. The gate shows +0x121 rising with a scripted Down and falling with its release, the same on native vs2 and ours, so it is the crouch flag. The rig is P1 Donovan holding Down over frames 2840-2870; a control run with the Down deleted must never raise the flag. The pictures show the rise, the last held frame and the fall, each leg on its own frames; Demitri is each game's own art.

**What isn't covered.**
- +0x121 in the air, while blocking, or on P2 (P2 never crouches here).
- What the two lists do beyond choosing the hit path.
- No hit is run against a guard: the lists are read as lows and overheads.
- One character (Donovan), on MAME only.

## audit_df_accumulator

**Why the gate looks the way it does.** It settles what a fighter's +0x161 counter is for. A reading of the code had
given it to Aulbath, never observed live; measured, it is Sasquatch's Dark Force armor. While the armor is armed, each
hit adds to the counter and causes no reaction until the sum passes 60; that hit reacts normally and the sum starts
again. Sasquatch is legacy content, so the comparison is pristine vsavj against our build, whose trace must be
byte-identical (the superset invariant). So the two rows of pictures are expected to look the same.

**What isn't covered.**
- vs2 has no Sasquatch, so nothing is measured on vs2.
- The HP+HK activation and the no-stock legs run on pristine vsavj only and are not drawn.
- One replay, with Victor's cr.LP, cr.MP and cr.HP as the hits and the stocks poked.
- MAME only; the build the gate is given (`BUILD`, default `build/m3b_merged31`).

## audit_df_meter

**Why the gate looks the way it does.** The gauge code is the same in both games except for which mode it tests, vsavj's Dark Force Change or vs2's Dark Force Power, and the tenants carry vs2's copy. So under our Dark Force Change their copy never saw the mode, and until the 14z-170 fix (#157) they gained +6 gauge per swing in it. The maintainer agreed that no gauge should be built during Dark Force: the shells' behaviour is the rule. P2 is kept out of reach so every attack whiffs and only start-up gauge can move: j.HP and 5HP, out of the mode and in it. The vs2 legs, shown for reference, enter by the tenant's EX install and do pay gauge; where a leg builds none, its picture is taken at the reference leg's step frame.

**What isn't covered.**
- P2's gauge, and gauge paid by a hit in the mode beyond these rows.
- The other effects of vs2's Power flag in the tenants' code; a static census names the places that read it.
- MAME only, with real cursor picks and the speed level pinned.

## audit_df_modes

**Why the gate looks the way it does.** The maintainer pointed out, on #136, that vs2's P+K is not the same mode as ours: on vs2 it is the global Dark Force Power, on vsavj and ours each character's Dark Force Change. The gate freezes, for every selectable character, what P+K does on each game: vs2's Power costs two stocks and gives no startup invincibility. The tenants' vs2 EX moves (Slay Shred, Ray of Doom, Shining Gemini) are different: they reach each tenant's Change handler on both games. So on the main sheet the vs2 row shows a different mode by design: that difference is what is frozen. Characters vs2's wheel lacks (ids 02, 09, 0a) have a vsavj leg only, and the tenants' EX legs are on a sheet of their own.

**What isn't covered.**
- Whether other inputs also reach the vs2 EX moves.
- What the modes do beyond the fields traced: the altered attacks are not checked here.
- Sasquatch's alternate Dark Forces, and activations on the P2 side.
- Stocks are poked and the speed level and RNG pinned, on MAME only.

## audit_df_moves

**Why the gate looks the way it does.** #136's rigs outran the 360-frame Dark Force, and the maintainer agreed that
needed a rig change. The first version compared our P+K with vs2's P+K, a different mode (Dark Force Power); the
maintainer caught it, so a tenant's vs2 reference is his personal Dark Force, a timed EX move. Our leg presses P+K, the
native leg the tenant's vs2 EX input, one event per activation, and both legs must enter the mode every time or the
leg is void. All 29 events match in hits and damage but for known remaps; the gauge differs by two ruled rules. The
CONTACT group (#109's Phobos beams, #178's Hop Kick) must hit on both legs.

**What isn't covered.**
- That the named move came out as that move: the gate proves P1 acts, and the printed state paths show what it did.
- A jump normal's attack is not told apart from the jump itself.
- The level and RNG pins, like the inputs, are written on every frame of every compared window on both legs.
- The form rows (Pyron's palettes, Donovan's sword) are measured, not drawn; the two modes look different by design.
- MAME only; the build the gate is given (default `build/m3b_merged31`).

## audit_df_startup_invuln

**Why the gate looks the way it does.** The maintainer asked (2026-08-31) whether the three tenants get the invincible
startup window vanilla characters get when Dark Force starts, and if so whether it is shared by everyone or inherited
from their shell character (Bulleta for Phobos, Demitri for Pyron, Victor for Donovan). The measured answer is neither:
each tenant arms its own vs2 window (Phobos 0x4F, Pyron 0x29, Donovan 0x40), as each vanilla character arms its own. The
legs are the 15 vanilla characters on pristine vsavj, the three shells and the three tenants on our merged build, and
Donovan on native vs2. A shell's trace on our build must be byte-identical to pristine vsavj (the superset invariant).
The contact pictures (Victor's 5HP inside and outside the window) are judged against the ruled expectation, not another
leg.

**What isn't covered.**
- Native vs2's leg is no reference for the window: its Dark Force (P+K, Dark Force POWER) is a different mode that
  never arms one.
- Phobos's contact legs are reported, not asserted: his Dark Force is a flight mode, and the late attack may miss.
- Contact is checked with one attack, Victor's 5HP, against Demitri, Donovan and Pyron.
- MAME only; one activation replay and one contact replay; one build (default `build/m3b_merged31`).

## audit_dmg_legacy_sweep

**Why the gate looks the way it does.** It was built for #191, not for the superset invariant. #191 began as a tenant
question: Donovan took 9 HP from Demitri's 2HK on our build but 8 on native vs2, and the worry was that the +1 was ours.
To settle that, the gate compared vsavj with vs2 on every legacy victim. It showed the two original games already
differ: vs2 lowered Demitri's own attack records (10/14/20 → 9/13/18), and swapping those records swaps the damage both
ways. That's why #191 closed as not-ours. Since #295 the gate also runs every legacy leg on our build, judged exact
against vsavj: each trace byte-identical and every hit equal. So on a legacy sheet, vs2 against vsavj shows the
difference between the two original games, and ours against vsavj shows there is none.

**What isn't covered.**
- The legs start from character ids written into memory after the select screen, so neither the select screen nor a
  cursor pick on our wheel is checked here.
- One level (6) and one RNG value (0000), pinned on every leg, and one damage-level config byte (never varied);
  MAME only; the build the gate is given (`BUILD`, default `build/m3b_merged31`).
- Demitri's 2HK, 5HP and 623HP only: other attackers and moves are not checked.

## audit_don_grab_pose

**Why the gate looks the way it does.** It was built for #104. The maintainer saw a tenant held in Victor's
headbutting grab (6+HP) in a half-right, half-squished pose, and named Donovan and Phobos. The hold pose comes from a
capture record chosen per victim, and on vsavj the newcomer rows are copies of the base rows, so a tenant got the
record of the character it folds onto: Donovan got Victor's, Phobos got Bulleta's. So the gate compares ours against
native vs2, the game the tenants come from, and checks that each tenant victim gets the same record as on native. Section
0 is a legacy control victim: both games must agree on it, which also proves both rigs made the hold, or every
tenant verdict is void.

**What isn't covered.**
- Victor's 6+HP grab is the only attacker and grab checked.
- The victims are one legacy control and the three tenants (`VICTIMS` can change the set).
- The record is read as a number; each game's stage, palette and a legacy victim's art are each game's own, and the two
  legs reach the hold on different frames.
- MAME only; the build the gate is given (`BUILD`, default `build/m3b_merged31`).

## audit_entrance_draw

**Why the gate looks the way it does.** On #136's guard-cancel rigs the two legs opened differently: native drew Phobos's car arrival, ours the arrival with Cecil in hand. The question was whether our build can draw the car arrival at all. The entrance is drawn from the RNG at character load, and the two games use the RNG differently, so one seed gives different entrances on each. The gate runs six seeds and compares the SET of entrances: both legs draw the same three variants (0 the drive-in, 2 and 6 held). A draw whose variant and position disagree is VOID.

**What isn't covered.**
- Which entrance one seed draws: it differs between the games by design, so the two pictures of a seed may not match.
- Phobos only, on one rig (huitzil_5), six seeds.
- MAME only, the RNG poked once and the level pinned.

## audit_ex_refused

**Why the gate looks the way it does.** The maintainer ruled the tenants' vs2 EX route into Dark Force disabled on our build. Before a byte moved, the gate measured what the input does on vs2 when the mode is refused, with no stock left. It runs each tenant's EX input (Donovan 421+KK, Phobos 263+PP, Pyron 2623+PP) on both games with the stock poked to 0, and to 3 as the positive control. Since the fix, no leg of ours enters the mode; Phobos and Donovan at stock 3 follow vs2's refused path, and Pyron does 623+PP, his ES move. So on a sheet, ours at stock 3 is meant to match vs2 at stock 0.

**What isn't covered.**
- Which move a path is: that is for the maintainer to judge from the pictures, not frozen here.
- Inputs from the P2 side.
- Inputs other than these three.
- MAME only, the stock poked, the level and the RNG pinned, frames 3255-3400 only.

## audit_facing_rule

**Why the gate looks the way it does.** It was built for #159. An attack record tells the victim which way to face, as a rule number; vs2's code knows rule 5 and vsavj's does not, and our tenants run on vsavj's engine. Before M21 that left a wrong value in Demitri's facing byte on ours, so the returning wave of Donovan's Killshread Summon (ES) dragged Demitri toward Donovan on native but left him in place on ours. Since M21 a fix teaches vsavj's code vs2's rule 5, and ours writes native's values; Demitri ends at x 755 on both legs. The pictures are each write to his facing byte from frame 3850, and his x at 3924 and 3946. A static part also reads both games' code and counts the legacy records that carry rule 5.

**What isn't covered.**
- Donovan's other rule-5 records (#159).
- What held ours at 835 before the fix.
- Tenants on the P2 side.
- One rig (donovan_3), frames 3850 onward only, MAME only.
- The address that does the write: ours writes from the fix's own place, by design.

## audit_facing_sweep

**Why the gate looks the way it does.** #159 is Donovan's Killshread Summon (ES) pushing Demitri away where native drags
him in: vsavj's hit code XORs facing rule 5 into the victim's facing. The gate moves the players before the Summon to 32
positions, so its six contacts land on different animation steps and on both sides of Demitri, and at each one compares
our build's facing writes with native vs2's, write for write. It also asks whether a data-only fix could match native
everywhere: across these positions native gives both 1 and 0 on the same step, where no vsavj rule gives both, and the
maintainer then ruled for Design A. Since M21 all 32 positions are expected to match. Each picture is at one of native's
rule-5 facing writes, at that frame on both legs.

**What isn't covered.**
- Demitri only stands: he never moves or blocks; Donovan is always P1.
- The other four rule-5 attack records are not exercised.
- A fix that changes the structure of an animation step is not considered as a data fix.
- MAME only, not FBNeo or MiSTer; the level and RNG pinned.
- Each game's stage and palette, Demitri's art (each game's own copy), and the code address of each write.

## audit_fg_parity

**Why the gate looks the way it does.** It checks that Phobos's EX Final Guardian (623+2K) deals the same damage on our build as on native vs2. Before the fix, the ported damage code put its damage where vs2 keeps it, which vsavj never reads: twelve ticks counted but almost no HP, ours 1/1/1/1/1 against native 23/23/23/23/52. Both legs must equal the frozen native staircase over five attempts, with 12 HP ticks each and one stock spent per attempt as the sign the EX version fired. The native leg is re-measured every run, so a drifting reference fails as loudly as ours. The fifth attempt lands in the corner, 11 beam ticks plus one 30 HP final hit, hence 52.

**What isn't covered.**
- One replay, five attempts, Victor as the victim; both character ids are poked, not picked on the select screen.
- Only the HP damage and tick counts are judged.
- MAME only. Not comparable: each game's stage and palette, and Victor's art.

## audit_flicker_attribution

**Why the gate looks the way it does.** Some frozen legacy expectations allow a flicker frame, where our build and
vsavj differ; such a frame is a claim about the build, so it is not written into an expectation until it is
attributed. The gate re-derives each attribution in every run instead of trusting the commit that first wrote it:
every differing byte at those frames must fall inside a named window, either the palette-fade staging buffer rows or
the OBJ-builder's secondary stack. The staging buffer is display-only and short-lived. The stack shows where the
program is, not game state. Since #293 each case runs in a fresh sandbox, and its vsavj leg must equal the frozen
vanilla run at that frame, so the attribution is of the run the expectation describes.

**What isn't covered.**
- Only the listed frames are checked: 37_victor_ko +7168, 105_legacy_2pwin_auto +2713 and +5868, and +2093 of
  03_two_player_vs and five #118 replays.
- Inside the named windows the two legs are expected to differ, so a difference there is not a fault.
- The old case 41_don_altcolor_vsavj +2313 was retired: the build under test no longer flickers on that frame.
- MAME only; the build the gate is given (`BUILD`, default `build/m3b_merged31`).

## audit_grenade_ground_tiles

**Why the gate looks the way it does.** It checks that Phobos's 214+LP ground explosion draws vs2's own art. Earlier work judged from snapshots that it looked right and that the old "fuchsia" report was most likely fixed, but that was a guess; this gate measures every frame, by tile content, across both games. The two legs run about 5-6 frames apart, so a frame-by-frame comparison would read as disagreement; the gate instead compares the set of tiles drawn over the whole detonation. Measured: 441 tiles, all drawn by both, none blank. The "fuchsia" was always the explosion's correct orange-to-magenta fade.

**What isn't covered.**
- When each tile shows: the frame numbers differ between legs, and only the sets are compared.
- Only the explosion's own palette-06 tiles in the blast area.
- One replay (83d), where the bomb lands short and goes off on the ground.
- MAME only; Victor's art is each game's own copy.

## audit_guard_reentry

**Why the gate looks the way it does.** It was built for #136, where Phobos's Reflect Wall guard cancels read DIFF
against native vs2. The question was whether that comes from our port or from the host engine, so the gate runs the
same rig with Demitri, a legacy character, on vs2, vsavj and our build. When a block's freeze ends with back still
held, vsavj restarts the block animation on every frame back is held, and vs2 keeps ticking: a difference between the
two games' engines. Ours equals vsavj on every sampled field, and the first frame an attack is possible is the same.
So on these sheets vs2 is expected to differ from the other two; the stage palettes also differ between the games.

**What isn't covered.**
- Phobos himself is not traced here: Demitri is used to separate the engine from the port.
- Three guard-cancel events (frames 2800, 3220, 3640), offsets +8 to +25 only.
- The animation node addresses differ between vs2 and vsavj and are not compared.
- MAME only; level 6 and the random number pinned; Demitri on the default cell.

## audit_hitbox_parity

**Why the gate looks the way it does.** A record for #136 claimed exact hitboxes over 3,021 frames, and no gate, log
or file was found behind it. On this engine the boxes in play on a frame come from tables the fighter block points at,
chosen by the node's box ids, so the same hitboxes means the same node giving the same pointers and ids. The gate
compares ours with native vs2 on every frame where both legs are on the same node, over three naming rigs: donovan_1,
pyron_4 and huitzil_1. Our pointers are first translated out of the build's placements of the tenant; compared raw,
every pointer differs.

**What isn't covered.**
- Frames where the two legs are on different nodes: those are the parity gate's DIFF rows.
- P2's boxes: Demitri's hitbox families differ between the games.
- The bytes of the tables themselves, which are the charmap gates' subject.
- Three rigs only; level 6 and the random number 0000 pinned; MAME only.

## audit_hui_grunt

**Why the gate looks the way it does.** It answers the maintainer's 2026-08-18 grunt report. When Phobos is
electrocuted, the sound engine fires a voice on every other electrocution, chosen by the victim's class. On vsavj the
newcomer rows of that table copy the base rows, so Phobos fired a legacy character's hurt cry (0x1d2); native vs2 fires
his own id 0x2a2, a free id, which is deliberate silence. The gate runs the five-electrocution rig on ours and native
vs2 and compares the queued sound ids with a frozen list for the build; a build not yet measured is refused. A silent
id is still queued, which is what makes silence checkable.

**What isn't covered.**
- The sound itself: the gate reads queued ids, and 0x2a2 is silent by design.
- At the fourth electrocution ours drops the voice where native fires 0x2a2 again: measured, unexplained, not chased.
- One rig (replay 95) with Phobos as the victim; MAME only; the build the gate is given (default
  `build/m3b_merged31`).

## audit_landing_sound

**Why the gate looks the way it does.** Built for #223: vs2 gives Phobos the big-body landing sound and Donovan the ordinary one, and ours had the reverse. The maintainer ruled "#223 I confirm the sound effects should be swapped to match VS2", and the build from M23 on takes vs2's choice. The gate checks that the landing-sound code is reached on the same frames on both games, and that at the first landing the two games' audio differs no more than 4x what it differs a second earlier, so the landing no longer stands out. A control runs the same check on the build before the swap and must fail, which shows the check can detect the landing sound the swap removed.

**What isn't covered.**
- Phobos and Donovan only, always with the tenant on P1.
- Only the first landing is compared as audio; the later reads are compared by frame only.
- The level and the RNG are pinned; MAME only.
- Not comparable: the site's address (it sits at a different place in each game), each game's stage and palette, and P2's art.

## audit_legacy_pairings

**Why the gate looks the way it does.** It asks which replays are legacy content, and whether each one is compared against vanilla rather than against itself. It was built after 14z-88, when a replay named for Victor in fact loaded Jedah, carried an expectation frozen from the build's own earlier run, and so let a superset regression sit green. The filename does not tell what a replay loads, so the gate reads the fighters each replay actually loads, on vsavj and on ours. The gate judges the first frame of each fighter pair, each leg at its own frame; that frame is the load, so it shows no fighter and sits in the sheet's "Judged frames without fighters" strip, while the sheet itself shows up to 9 frames of that pair's own run with a round on (#291 S4-E), each proven on the gate's trace; the select wheel on ours has 21 cells against vanilla's 16 by design, and a load phase of a frame or two may differ. Since #293 every leg runs on its own fresh sandbox, so no run starts from an earlier run's saved data.

**What isn't covered.**
- No pokes: replays run bare, as the suite runs them, so what a replay means under its own gate's pokes is not judged here.
- Select-screen replays where no fighter ever loads are reported for hand judgement, not judged by the gate, which cannot see the screen.
- A legacy replay with a written `.legacy-exempt` reason may stay self-frozen; the reason is printed every run.
- Skipped replays are not checked; MAME only.

## audit_mask_window_ff4182

**Why the gate looks the way it does.** The legacy oracle ignores one small memory window, $FF4182-$FF41A1, the
palette-fade staging slot for select block-A row 14. It is ignored because the 14z-49 medallion recolour changes that
row by design, and venue fades pass it through this buffer even in legacy replays. The gate proves the window hides
that designed change and nothing else: at frame 9126 of `05_timeout_idle`, vanilla's slot holds vanilla's row, ours
holds the ported row, and every byte around the slot is identical. So the recoloured row is the one expected
difference between vsavj and ours.

**What isn't covered.**
- One frame of one replay: 05_timeout_idle at frame 9126.
- Only the bytes $FF4140-$FF41DF around the window; the rest of memory is left to the battery's masked gate.
- It is not part of the battery: it is run on suspicion, such as a new difference near $FF41xx or a retune of row 14.
- MAME only.

## audit_merged_legacy

**Why the gate looks the way it does.** It asks whether a program image carrying all three tenants at once changes anything for the original characters. When it was written, the merged patch applied but had never run in an emulator; this gate is the evidence that the merge behaves. It plays the legacy replays on our merged image and on vsavj, the superset invariant's ground truth, and each replay must land on its ratified comparison class: inside a ratified window the two legs are allowed to differ, and any other difference fails instead of being absorbed. The merged image here carries blank tenant graphics, so it is a legacy-only instrument that must never reach a playtest.

**What isn't covered.**
- The three tenants: they draw blank on this instrument by design, and the gate proves nothing about their correctness (a second leg only checks that their content runs without crashing).
- Merged against the single-tenant builds on the legacy replays is left out on purpose: both are already compared with vanilla.
- Only the replays with a frozen `.masked` expectation are judged; the `.pending` ones are named, not evaluated.
- MAME only.

## audit_move_parity

**Why the gate looks the way it does.** It was built for #136: does each move of Donovan, Phobos and Pyron behave on our build as on native vs2? Both legs run the same rigs with the same inputs, as real cursor picks, and the tenant's own state is compared every frame, with one verdict per event (IDENT, DIFF or VOID) for all 526 events. The speed level is pinned to 6 on both legs, because vs2 starts in TURBO and vsavj in NORMAL, and an unpinned comparison would measure the play mode, not the port. P2 is Demitri, each game's own copy of him, so his art may differ; only his HP is compared. On the Phobos parts huitzil_5/6/7, the first-event DIFF rows are the round-start entrance, not the move.

**What isn't covered.**
- The RNG is pinned to 0000, a value where every draw returns 0, so every random choice takes its zero path on both legs (#183).
- Hitboxes and projectile settings: those are separate gates.
- P2's position is not compared, so a move that pushes Demitri differently reads IDENT until P1's own state feels it.
- Why a DIFF happened: that is `audit_move_parity_attribution`'s question.
- MAME only, at one speed level (6).

## audit_pass_overrun

**Why the gate looks the way it does.** 29 of #136's 108 DIFF rows begin on a frame where the pass counter does not
step on one leg, right after a double-pass frame. On three Blizzard Sword frames a double-pass activation runs past
the frame, so one frame completes no logic pass: twice on native vs2 (`donovan_2`, `donovan_11`), once on ours
(`donovan_10`). It is not a port cost: native loses the pass in two of the three parts, and the scheduler's idle time
per event window is equal on both builds within about 1%. The host engine's clock governs; the maintainer, #114: "we
must respect the fact that we are porting the character to a different engine and the engine, being vanilla vsav,
takes precedence."

**What isn't covered.**
- Three parts only (`donovan_2`, `donovan_10`, `donovan_11`), the committed rigs with the parity gate's pins.
- After a leg's lost pass the legs are one engine pass out of step, by design of the measurement.
- MAME only; the build the gate is given (default `build/m3b_merged31`).

## audit_phobos_dmg_residual

**Why the gate looks the way it does.** After the M19 fix gave Phobos vs2's defense rows, he still took one more HP than on native vs2 from Demitri's 5HP: 12 against 11, at three RNG pins. This gate was the reproducer for #161. A legacy pair then showed the same +1 with no port in the loop: Demitri's 5HP on Victor reads 12 on pristine vsavj and 11 on pristine vs2. The cause is Demitri's own 5HP record, 14 on vsavj and 13 on vs2, so #161 was ruled not ours, and the gate is kept as the record. On the sheet, Phobos's hits show native vs2 above ours, and the legacy pair shows vs2 above vsavj; the damage on the legacy pair differs between the two games, as expected.

**What isn't covered.**
- Why the extra point appears: this gate shows it, and `audit_dmg_legacy_sweep` measured the cause.
- Other attackers and moves; Donovan; FBNeo and the MiSTer core (MAME only).
- Two rigs only, the naming parts huitzil_5 and huitzil_6, with the speed level pinned.

## audit_projectile_clash

**Why the gate looks the way it does.** It asks whether Pyron's Cosmo satellites can meet other projectiles on our build as on native vs2. On both games they cannot: their hit-row index (+0x94) is 0, so the projectile sweep never picks them up. That is measured native parity, not a defect (#108). There are three legs: a Demitri-vs-Demitri control that must show the sweep alive, Pyron's rig on our build, and the same rig on pristine vs2 as the anchor. The bank word differs by design, 0x6000 on vs2 and 0x1000 on ours, because our WIDE layout needs its own value and 0x6000 there garbles tenant sprites.

**What isn't covered.**
- Only Pyron's Cosmo satellites, on one rig.
- The bank word itself is not compared between the games: each game's own is correct.
- MAME only.

## audit_pursuit_flag

**Why the gate looks the way it does.** It was built for #195: after Cosmo Disruption, Pyron could not pursue on our
build. vs2 marks a knocked-down victim as open to a pursuit only for reaction class 0x51, and our tenants' 0x51
records are remapped to 0x44, which never sets that mark until #195's two hooks are applied. The gate compares ours
with native vs2 on two rigs, Pyron's Cosmo Disruption and Donovan's Ifrit Sword (ES), each followed by up+LP. It reads
from the build itself whether the hooks are there: with them every event must equal native, without them the known
gap, where the pursuit never starts on ours. A third rig, Donovan's Lightning Sword (ES), holds #200's answer: no
pursuit starts on either game.

**What isn't covered.**
- Pinned play only: level 6 from frame 2000 and the random number 0000 from 2363.
- The pursuit with the tenant on P2: that side is checked only at the mark, not the pursuit.
- Only the three rigs' moves: the LP, MP and HP Lightning Swords, other distances and unpinned play are not measured
  for #200.
- FBNeo and the solo tracks.
- The mark taps (`pyron_4`) run on ours only and are not drawn.

## audit_pyron_capture_block

**Why the gate looks the way it does.** Pyron's throws now hold the victim with his own capture block from vs2, ported at 14z-143. Before that, vsavj's row for him pointed at Demitri's block, so the held victim's position and pose differed from native vs2. The gate compares ours against native vs2, the game Pyron comes from, as the maintainer ruled. Demitri throws first as the control: he must look the same on both legs, which proves the rig made the hold on both and that both legs are read the same way. The pictures show Victor held under the 6+HP throw at the first and middle held frames; each game draws its own stage, palette and Victor, and the legs reach the hold on different frames.

**What isn't covered.**
- Donovan and Huitzil: their holds are checked by `audit_don_grab_pose` and `test_hui_grab_victim`.
- One throw and one victim: Pyron (and the Demitri control) against Victor on one replay, `judge/02_throw`.
- The hold offsets are compared as numbers; no reading of them as "N pixels up" or "thrown behind" is established.
- MAME only, on the build the gate is given (`BUILD`, default `build/m3b_merged31`).

## audit_qs_voice_wav

**Why the gate looks the way it does.** It records the whole voice sweep as audio on ours and native vs2 and compares each voice's loudness (RMS) and high-band energy. It exists because it caught a defect every other gate passed: samples packed across a bank's 0x8000 offset were cut short, while registers, records and bytes were all correct. Each cell is a playable clip of one voice, because the test-mode sweep shows nothing worth a picture, and the ids under each pair differ by design: ours are authored ids, vs2's its own.

**What isn't covered.**
- The data side (registers and sample records): that is `audit_qs_voice_batch`, which answers a different question; both are kept.
- Only two measures per window, loudness and high-band energy.
- Only the voices of the test-mode sound sweep, not voices played in a match.
- MAME only.

## audit_rig_opening

**Why the gate looks the way it does.** Built for #168, part of #136: ten rows of the move-parity table differed on x with no move involved. Seven naming parts pinned both fighters' position at frame 2370, but the round starts at 2545, so the pin landed inside the round-start entrance, and the two games draw different entrances: native the car arrival, ours the arrival with Cecil in hand. The maintainer identified the two entrances on the capture. So on this sheet the frames before the first pin should differ; the gate claims only that every part's first pin lands after the round start, and that from then on the legs agree at every sample.

**What isn't covered.**
- The entrance itself: it is native behaviour on two different games, and its rows are frozen as measured, not judged equal.
- Only huitzil_5 is traced; for the other parts only the first pin frame is read, from the committed schedule.
- The pin frame itself is left out of the agreement check, because x is the field the rig pokes.
- MAME only. Not comparable: each game's stage and palette, and P2's art.

## audit_rng_draws

**Why the gate looks the way it does.** It was built for #176. The parity gates pin the RNG word every frame, so a
defect in how the RNG advances would be reset away on both legs. This gate seeds the RNG once, lets it run free from
frame 2600, and compares the draws by who called them. Legacy content (Lei-Lei against Demitri) on ours must equal
pristine vsavj draw for draw; each tenant on ours is compared with native vs2. vsavj's motion trackers draw a random
step timeout where vs2's write a constant 16, and the tenants' tracker calls run vsavj's on ours, ruled host behaviour
(the maintainer: "Host behaviour, no ticket"); so the callers' addresses differ by design, and those one-leg counts are
frozen.

**What isn't covered.**
- Seeds other than 5a5a, and seed frames other than 2600.
- P2; the naming corpus and other rigs; turbo speed.
- FBNeo and MiSTer.
- A call made by a jmp or a pushed return, and stack deeper than 48 longs.
- What the tracker timeout does to a player's inputs. The parity gates' 0000 pin is #183.

## audit_shared_wall_push

**Why the gate looks the way it does.** It answers #179: after a throw, at Phobos's Sitting Attack landing, native Phobos keeps the corner and ours is pushed out. When both fighters are against the same wall in the same frame, the push-apart code is the same in both games, but vs2's screen-edge clamp sets a flag that swaps who gets pushed: vsavj pushes P1 out, vs2 pushes P2 out. The tenants run on vsavj's engine and follow its rule, ruled the host engine's behaviour, documented, not ported. The `legacy_lilith` part is the maintainer's control design: Lilith and Victor with the same setup on pristine vsavj and vs2, which shows the difference is engine-wide. Its sheet has no leg of ours. The `huitzil_3` part runs the rig on vs2 and ours.

**What isn't covered.**
- The attacker as P2.
- The left wall: every rig is at the right corner.
- The resolver's airborne and +0x115 branches.
- Sitting Attack event 9.
- The two instruments share MAME, the rig and the pokes.

## audit_tenant_cpu_soak

**Why the gate looks the way it does.** Built for #129, which asks whether the tenants' CPU AI is lackluster on our build. Their AI blocks are byte-identical to vs2's, so the gate measures what the CPU does: Phobos, Pyron and Donovan as the CPU, ours against native vs2, over one long round with P1 standing still and with P1 active. The random choices are not pinned, so the legs part ways from the first random draw and the pictures are samples, not matching frames. What is judged is how often each move, state and command shows up, the mean distance and the airborne time, and how far the two legs' figures are apart, all frozen as measured. The gate does not judge "plays the same": what the figures mean is the maintainer's to read from the sheets.

**What isn't covered.**
- The meaning of the AI's commands and scripts (not decoded).
- Any player behaviour but the two fixed ones; a CPU that is losing (HP and the timer are pinned, so P1 never wins a round).
- Later ladder rungs, difficulty settings other than the default, and FBNeo.
- A frame-by-frame comparison of the two legs.

## audit_tenant_throw_geometry

**Why the gate looks the way it does.** The maintainer asked whether Phobos's three throws (6+HP, Circuit Scrapper, ES
Circuit Scrapper) match their vs2 versions; #230 added Pyron's and Donovan's standard throws and #235 Pyron's air throw.
These throws mostly move the victim rather than change its sprite, so the gate follows where the victim is held relative
to the thrower, every frame of the hold, in order, and the damage. The reference is native vs2, because the tenants come
from there; both legs run the same replay with the same thrower and victim, at the same speed level and RNG. Five
victims are never held by Pyron's air throw on either game; their sheets show the press frame instead of a hold.

**What isn't covered.**
- The victim's pixels: each game draws its own generation of the victim's art, and pose is compared through each
  game's own pose table, so a picture difference in the victim is a cross-game fact, not a fault in the port.
- How long each pose lasts is reported, never asserted.
- Why those five victims are never held is not measured.
- Damage is compared as totals per victim; Sasquatch's damage difference is frozen as measured (vanilla's own defense
  row).
- MAME only; level 6 and RNG 0000 pinned; one build (default `build/m3b_merged31`).

## audit_throw_registration

**Why the gate looks the way it does.** Built for #157, from #136's meter differences: at a throw the game records who is attacker and who is victim just before it hands out meter. Up to M19 our ported throw code wrote that record where vs2 keeps it, a place vsavj never reads, so the attacker got the victim's flat 8 meter and the victim got the throw's; since M20 it writes vsavj's own record and ours pays like native vs2, which the gate freezes for each tenant. A legacy control, Demitri throwing Victor on pristine vsavj and on vs2, shows both games record the pair and pay the attacker the same way, so the fault was the port's, not a difference between the two engines. A fourth part, donovan_2_ko, forces a KO to reach a third store (#180). The meter steps and addresses are judged as rows against the frozen file, not between the pictures.

**What isn't covered.**
- Four tenant parts and one legacy throw; other throws are not checked.
- The KO is forced by writing the victim's HP to 4, not played.
- Speed level 6 and the RNG are pinned on every leg; MAME only.
- Not comparable between the pictures: each game's stage and palette, and the victim's art (each game's own copy).

## audit_trap_air_hit

**Why the gate looks the way it does.** #175 asked whether Phobos's Plasma Trap dome can hit an airborne opponent at
all. An earlier gate had shown a jumping Victor is never hit in the air; 14z-182 found why: the dome's box is flat, its
top 6 px above the ground, and a jumping Victor's hurtbox ends 33 px above his feet. Felicia's j.HP has an animation
step (node 4) whose hurtbox reaches below her feet, so this rig drives it: pressed at 3508 she is hit on her last frame
before landing, in the air (class 0x07, the air stager); pressed at 3511 she is hit on the landing frame, the ground
path. Ours matches native vs2 in every traced field. The victim is each game's own Felicia (the superset invariant), so
her head hurtbox differs between the legs, frozen per leg; ours is checked equal to pristine vsavj.

**What isn't covered.**
- One move, Felicia's j.HP: other jump attacks whose hurtboxes reach the feet (found on six characters) are not
  driven.
- At 3511 the class byte differs by ruling: 0x52 native, the marker 0x38 ours.
- Both fighters are placed by position pokes before the window; level 6 and RNG 0000 pinned; MAME only; one build
  (default `build/m3b_merged31`).
- Each game's stage and palette.

## audit_trap_airborne

**Why the gate looks the way it does.** #163 left one question open: what does the Plasma Trap dome do to a victim in the air? Here Victor jumps while the dome is active: he clears it in the air (apex 127) and is hit on the frame he lands, on both legs. From that frame the shock plays as on the ground, identical on native vs2 and ours except the class byte: 0x52 native, the marker 0x38 ours, by ruling. The ground is height 40, so "in the air" means above 40, not above 0; the gate's first form got this wrong. The pictures show the take-off, the apex, the last airborne frame and the landing hit, each leg on its own frames.

**What isn't covered.**
- A dome hit on a victim still in the air: none happens in this rig (#175).
- A lower jump arc or a juggled victim is not tried.
- Other jump timings: five more run only with `SWEEP=1`, printed and never frozen.
- The solo Phobos track; MAME only.

## audit_trap_parity

**Why the gate looks the way it does.** It checks the Plasma Trap's sounds on our build against native vs2, on the same far/timer replay. Native vs2 fires 0739 when the mine appears, then 010b, then 073a when it detonates on its timer; on vsavj 0739 and 073a are music, so ours must never send them: their appearance would be the music bug. Ours plays restored twins instead, 00d8 for the ejection and 0199 for the detonation chirp, so the ids under the pictures differ by design and each leg is held to its own frozen list. The native leg is re-measured every run, and the background id 049a must appear on both legs as proof the sound log is live.

**What isn't covered.**
- The sound itself: the log holds ids, not audio, so whether the restored sounds sound like native is not judged here.
- Two attempt windows of one replay (frames 3400-3900 and 4200-4700); MAME only.
- Not comparable: each game's stage and palette, and Victor's art.

## audit_trap_shock

**Why the gate looks the way it does.** Phobos's Plasma Trap dome must shock its victim. Its hit records carry vs2's
extended class 0x52, which vsavj's victim-reaction table does not reach, so unfixed it lands as a plain hit. Native vs2
is the anchor, and two of our builds are measured against it: the merged build, which ships, plays vs2's rule (the
victim shocked, Phobos exempt from the attacker freeze); the solo Phobos build keeps the older remap and its attacker
freeze, by ruling (S1), because it lacks Donovan's machinery. The class byte reads 0x52 native, 0x38 merged and 0x06
solo by design. The speed level and RNG are pinned on every leg, because vs2 defaults to TURBO and vsavj to NORMAL;
pinned, native and merged are frame-for-frame identical over the dome window.

**What isn't covered.**
- The solo build is not held to vs2's rule: its attacker freeze is asserted present.
- Only native and merged must be frame-for-frame identical; the solo leg is not compared that way.
- One rig (replay 92, the deep-overlap trap) with Victor as the victim, on MAME only.
- Each game's stage and palette, and Victor's art (each game's own copy).

## audit_victim_parity

**Why the gate looks the way it does.** #136's census found the tenant AS VICTIM measured against native nowhere: the older reaction test ran the native leg only. Here Victor attacks the tenant with every kind of contact, on vs2 and on ours, both by real cursor picks, and the tenant's reaction is compared: the class byte, the freeze, the chain it runs and the frames until it stands again. Victor is the attacker because his attack chains are the same data in both games; his chains that differ are his own reactions, which he never enters here. The level is pinned to 8, vs2's TURBO, because the rigs were tuned there. On throw rows, Victor's throw start is one frame shorter on vsavj, so most throw hits land a frame earlier on ours: his data, not ours. Pyron's different heavy-hit reaction is #173.

**What isn't covered.**
- The contact frame is printed, not compared (#168), so the two pictures of a row may sit on different frames.
- P2's HP: the defense rows are ruled elsewhere.
- Victor's own reactions: the tenant never attacks here.
- Which attack made the contact: the event name is the rig's, the class byte the engine's.
- MAME only, the level pinned to 8 and the RNG to 0000.

## audit_win_pal_auto

**Why the gate looks the way it does.** It locks #105: with AUTO chosen by the winner, the victory screen drew a tenant winner's portrait white. The colours were not missing, they arrived late, after the screen. AUTO here is AUTO-GUARD, not autoplay. The legs: our build with AUTO, our build without AUTO, pristine vsavj with AUTO, the 1P vs COM screen, and a legacy winner (Demitri). The vsavj leg is the not-ours control: vanilla draws its own AUTO winner in colour, so the white was ours. Since the fix every leg must read coloured. The legs use different winners and replays, so each picture is that leg's own screen, not the same moment side by side.

**What isn't covered.**
- There is no vs2 leg: the reference is vanilla vsavj.
- The verdict reads the first 16 colour words of one palette window (0x90C2A0), scanned for a white run or a real colour ramp; the rest of the screen is not judged.
- Five runs only, one legacy winner (Demitri), MAME only.

## test_don_immortal_native

**Why the gate looks the way it does.** The gate asks whether Donovan's Lightning Sword (421+P) lands the same hits on
our build as on native vs2: the hit count, the damage and the frame of each hit, at every strength, with no mash and
at the fastest mash (#114). Native is measured in the same run, because an older gate checked this move on our build
only and took native's figure from testimony. It also checks who was picked before it believes a number: in #114 the
leg called ours was really Jedah. Every leg pins the speed level and the random number, because vs2 starts at TURBO
and vsavj at NORMAL, and the two games' random draws decide which fighter moves first on each pass (#135, #142). So
the pictures pair hits at level 6 and at level 8; the stage, the palette and Victor's art differ because each game
draws its own copy.

**What isn't covered.**
- Durations tick by tick: the right instrument, `tools/tick_durations.py`, is tied to vsavj and is not run here.
- Mash rates between no mash and the fastest have not been re-measured.
- Unpinned play: the legs with the level or the random number left free are controls that must differ, and they are
  not drawn.
- MAME only, at levels 6 and 8 only.

## test_gfx_menus

**Why the gate looks the way it does.** The RAM gates cannot see graphics. In session 14r an overlay corrupted the title screen, the select screen and the speed menu while every RAM gate stayed green, and only playtesting caught it. So this gate compares the pixels of three screens on ours against frozen vanilla pictures: the title at frame 650, the select screen at 950 (Demitri hovered) and the speed menu at 1250. On 950 and 1250 the medallion cell box is masked, because our wheel is ported by design; everything else must match exactly.

**What isn't covered.**
- The masked medallion box: `test_don_colors` checks it.
- Only these three screens, at these three frames.
- MAME only.

## test_hui_df_style

**Why the gate looks the way it does.** It answers a playtest report: in Dark Force, Phobos gets afterimages and a
purple recolour, and native applies neither. The gate runs replay 85 unchanged on native vs2 and on our build and
compares the palette and afterimage evidence at the reported phase. It refuses to judge unless both legs show Dark Force
really active (the match-level flag set and a stock spent): the first version compared two matches in which Dark Force
never started, and every number agreed. The expected result is "differs": an earlier palette fix was withdrawn because
it wrote Bulleta's Dark Force block and drew a vanilla character wrong, so his purple Dark Force is on purpose until he
has his own palette block. Frame 3180 is the control frame, before Dark Force.

**What isn't covered.**
- Full equality with native is not the target: the two games run different Dark Force systems, and their palettes are
  one ramp step apart.
- Only five frames of the sprite list are compared: 3180, then 3400, 3440, 3540 and 3560 in Dark Force.
- Each game's stage, and Victor's art (each game's own copy).
- One replay, MAME only, one build (default `build/hui61`).

## test_hui_electrocute

**Why the gate looks the way it does.** STATE twice recorded that no existing replay produced an electrocute, so the maintainer's 2026-08-18 sound report had no instrument; this gate is that instrument. Phobos is the victim on ours and on native vs2, and the trigger came from the maintainer: Victor's held HP, "the electrocuting version of his HP", a chargeable normal, not a special. A quick press of the same button lands an ordinary hit, so the gate keeps it as a negative control: it must not install the electric shake. Over the electrocute window the two legs' sound ids agree id for id.

**What isn't covered.**
- The extra sound the maintainer reports at the end of the electrocuted state is not asserted: ours fires two Phobos voices native does not, but before the match, and the native leg reaches Huitzil by a poke the arcade ladder can rewrite, so it may not be voicing as Huitzil at all.
- The sound ids are frozen only over the electrocute window, not the whole run.
- One replay (93), MAME only.
- Not comparable: each game's stage and palette, and Victor's art; the sound ids come from separate runs, so the pictured frames are from the dump runs.

## test_hui_grab_victim

**Why the gate looks the way it does.** Before the 14z-73 fix, the victim of Phobos's grab teleported about 109 px
mid-animation: the start and end looked right, but the held part did not. The gate checks that our build places the
victim through the whole hold as native vs2 places him. The two games' screens are shifted by a fixed ~21 px camera
offset, so the gate compares the victim's offset from the attacker, not where either stands on screen; the pictures need
not line up exactly. It refuses a leg that never grabbed (no grab state or no grab damage), because a missed grab
measures nothing. The expected result is a match, with a peak difference of 0.

**What isn't covered.**
- Absolute positions on screen, each game's stage and palette, and Victor's art (each game's own copy).
- Only the victim's horizontal offset from the attacker (p2x - p1x) is compared.
- One replay (80) with Victor as the victim, MAME only, and the build the gate is given (default `build/hui61`).

## test_hui_oracle

**Why the gate looks the way it does.** It is Phobos's whole-moveset check with native vs2 as the oracle: one replay
(90) runs on native vs2 and on our build with identical inputs and pokes, and the RNG fixed. It holds four locks: the
match-start anchors are equal; in the neutral window every mapped field agrees on every frame; the sequence of P2's HP
values is equal on both and ends below 0x120; and the count of cross-game mismatches is no more than an unchanged legacy
pair shows. That pair, the veteran control (stock vsavj against vs2), measures the engine-latency noise between the two
games. The pictures are at the match start and at each change of P2's HP.

**What isn't covered.**
- Ids, hitbox bases and animation pointers are skipped: they depend on where data is placed.
- Only the neutral window must match exactly; elsewhere ours may differ from native as much as the veteran control
  pair differs.
- Each game's stage and palette, and P2's art (each game's own copy).
- One replay, MAME only, and the build the gate is given (default `build/hui61/rompath`).

## test_m2a_stage4_oracle

**Why the gate looks the way it does.** The M2a stage-4 gate: ported Donovan on vsavj against native Donovan on
vs2, with identical inputs on both games: P1 Donovan, P2 Victor, then a scripted battery. "Ours" here is the stock
twin, where Donovan takes slot 0x0F, not the merged build. The match must start on the same frame on both, and the
idle window must agree on every mapped field, every frame. In combat a frame-exact comparison is impossible, because
the two engines differ by about a frame of action latency. So the gate checks that the values of P2's HP changes are
equal, and that Donovan diverges across the games no more than Demitri, an untouched character run on both.

**What isn't covered.**
- Ids, hitbox bases and animation pointers are skipped: they move with placement by design.
- Combat frame by frame: only the HP values and the mismatch bound are judged.
- One battery against Victor, Donovan only, on the stock twin (default `build/m5_stock22/rompath`); MAME only.

## test_pyron_blink

**Why the gate looks the way it does.** Pyron's sprite and his in-match HUD mugshot share palette row 10. Before the
fix that row changed every frame while native vs2 held it constant, so both blinked. The cause was a dead row: a
palette-routine table gave Pyron another row's animated handler where vs2 has a no-op. The gate runs one replay on
native vs2 and on ours with the same pokes, and counts the distinct row-10 values over 40 frames in a row, because the
two games are never on the same frame; ours must be constant and equal to native's. It looked like a Dark Force
recolour, but he was never in Dark Force on either leg.

**What isn't covered.**
- The in-match instance only: the same defect lived in two more tables, for the select screen and the route map, and
  `test_variant_dispatch` is the gate that covers them.
- Only palette row 10 is compared; each game's stage and Victor's art are each game's own.
- Pyron only: the header records Huitzil's matching row as latent and currently benign.
- One replay (76), MAME only, the build the gate is given (default `build/pyron46`).

## test_tenant_select_records

**Why the gate looks the way it does.** When the tenant moved off Jedah's slot 0x0F onto its own id 0x13, its select-screen pieces stopped being surgery on Jedah's records and became repointed rows plus records composed from vs2. The gate freezes that: the tenant carries its own select records, and the host's records go back to vanilla bytes. Most of it is checked without pictures: the bytes of the built image, three planted faults that must fail, and the records the engine reads as the cursor walks onto cell 0x13. The pictures come from one pick on replay 11, the frozen vanilla log against our build's, at the first and last frame of the window 889-2415 and the replay's sync anchors. Inside that window the two legs differ on purpose: our select wheel has added cells.

**What isn't covered.**
- One build: by default one built fresh at tenant id 0x13 (profile cps2-wide-v1), or the one given.
- The engine's reads are checked on the WIDE MAME build only, and `SKIP_RUNTIME=1` skips them.
- Only replay 36's walk onto cell 0x13 is traced for the engine's reads.
