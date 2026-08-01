# NEXT SESSION — orientation (written at context limit, session 14z-41, 2026-08-01)

Read STATE.md sessions 14z-36..41 after this. The maintainer tests
frequently and reports precisely — their reports are the project's
best instrument; reference data they provide goes straight into gates.

## Ship state — build 0a55bc58 (all maintainer-confirmed)

Battery: `ROMDIR="/Users/koneko/Developer/Vampire Saved/ROMS" tests/run_battery_m2.sh`
(57 checks; ~35 min; ROM audit runs first per CLAUDE.md §3).
Dev builds: `GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/donovan6`
(a bare build FAILS on 58 open reconciliation refs — expected).

Working & gated: select-screen sword (behind-flag composition);
color-aware accent (no sword/statue blink, any select button,
in-match); shock auras correct everywhere; sworded + swordless 421P
shock + electrocute death (record-type aliases 0x4E/0x50/0x51/0x52 ->
06/0F/4E/06, all vs2-dispatch-proven); column-KO crash fixed + gated;
alt-color + mirror native-exact; 421P multi-hit no-knockdown gameplay
lock.

## ACTIVE TASK — Lightning Sword hit count + animation speed

Symptoms (maintainer + measured): our sworded 421P always deals the
cap (7 LP / 11 MP / 15 HP hits) vs VS2's mash mechanic (base 3/5/7,
max-mash 5/9/11, ES 9-13; far HP = 6 by range); our animation runs
~11 frames/node vs native ~1.5-5 (visibly slower).

ROOT CAUSE PINPOINTED (14z-40/41): the move's anim runs through the
PORTED vs2 walker block (region x026142, placed at PRG:0x0CD390, len
0x1440; walker node-write PC ours 0xCE38A == vs2 0x2713C). The block
is byte-faithful except relocations. Divergence = **the reconciled
engine call at region+0xA8 (ours 0xCD438): vs2 0x082AE2 -> vsavj
0x073376. vs2's routine is a SPAWNER** (jsr 0x15702 alloc; beq;
move.l #$01006000,(a4); move.w a6,$30(a4) — TWICE = two owner-linked
support objects). **vsavj 0x73376 is an instruction-fragment tail
falling into rts = accidental stub — the objects never spawn.**

Plan:
1. Native role-tap: run `tmp` replay 48_immortal_v2 on vsav2 (P1
   Donovan R,R; 421+HP at 2610-2624; POKES supported in replay.lua/
   replay_guard.lua/tap_writes.lua as "frame:addr:hexbytes;...").
   Find the two spawned objects (tap writes of 0x01006000, or scan
   obj RAM ff9000+ for new alive objs at move start) and observe
   their behavior (hit pacing? input sampling?).
2. Find vsavj's true analog: search vsavj opcodes for the spawn
   pattern (jsr <alloc>; 671c; 28bc 0100...) — also verify what
   vs2 0x15702's vsavj analog is (the shared alloc). If no analog,
   port the ~0x30-byte helper (reconciliation patched_clone class or
   site_thunk-placed code) with its alloc call reconciled.
3. Fix the reconciliation row (build/manifest/reconciliation.toml,
   the row mapping 0x082AE2; current wrong vsavj = 0x073376), rebuild,
   measure: replay tests/replays/48_don_immortal_ko.rpl no-poke ->
   expect ~6-7 hits (HP version, this spacing) and node cadence
   1.5-5f (tap ff841c with REGLOG; walker PC changes from 0xCE38A
   pattern). Fatal path must still reach grounded node 0x158210.
4. Gate: extend tests/test_don_reactions.sh — no-mash hit-count upper
   bound (<=7 for HP at this spacing) + keep existing asserts. Then
   full battery; watch the frozen flicker inventory (standing watch).

Measurement kit: replays in tests/replays/ (48 = deity KO w/ HP poke
2600:ff8850:00010001; 50 = column crash, guarded); scratch replays in
/Users/koneko/.claude/jobs/*/tmp are GONE next session — recreate from
the replay comments. P2 HP = ff8850 (word, +white at ff8852). P1 obj
ff8400 (+0x1C anim node, +0x382 char id); P2 ff8800. Deity = P1's own
anim. vs2-side replay: picks P1 R,R / P2 R,R, motion L,D,DL+3.

## Queued after (in order)

1. Region-tail zeroed routine (x026142+0x142E, ours 0xCE7BE): the
   table_fix pad zeroed a per-char lookup (`move.w $100(a5),d0;
   move.w (pc-table,d0),$1A(a6); rts`). Audit callers (search for
   jsr/jmp to 0xCE7BE or region+0x142E refs); restore if called.
2. Swordless-deity palette (yellow vs vs2 blue figure/lightning —
   maintainer captures round 41). Same family as the deity's obj
   palette rows; untouched so far.
3. Select-screen post-confirm blink (tracked minor): select-venue
   objs lack +0x3A4 (cached block ptr) -> the color-aware accent
   thunks fall back to punch-color slots on that screen only. Fix
   shape: select-venue init of +0x3A4 or owner-link fallback.
4. ES Change Immortal presentation (records remapped to plain class
   0x4E-copy interim; vs2 intent = class 0x51/property 0x19) — ask
   maintainer if wanted.
5. Sounds: Donovan sfx silent by design (stubbed_sound rows; M5 task
   = dispatcher id-table translation, NOT unstubbing the helper —
   see reconciliation row note at vsav2=0x005122).

## Gotchas most likely to bite next session

- Read embedded/code tables from the right image: opcodes.bin for
  CODE, data.bin for embedded DATA (decrypt split). Zip program bytes
  are encrypted in 0x000000-0x100000 (hole a) — placed code there is
  stored re-encrypted; data-carrying thunks must use hole b.
- A0-in-REGLOG is post-increment (subtract batch size before deriving
  windows). Controls must vary the dimension under test (same-slot
  "controls" control nothing).
- POKE VALUES feed the CPU AI — any poke change reshuffles downstream
  choreography in multi-round scripted replays.
- The battery script builds donovan6 itself — never rebuild while it
  runs. Background any run >10 min.
- ROMDIR must pass tools/audit_roms.py first; keep it play-free.
