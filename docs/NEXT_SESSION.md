# Next session — 60-second orientation

Build: 2da7d910 (stage 6) — RESTORED again after the 14z-7 phantom-fix
revert (round 28; read STATE 14z-8 first). The SWORD SWING BLOCKER IS
FIXED (see STATE
14z-5 — the unmasked set-anim entry / patched_clone reconciliation fix).
Awaiting playtest confirmation (round 27): armed normals should show the
blade arcs; verify no new visual regressions (pixel A/B rule stands:
snapshots on replays 17/31 accompany any effect/display change).

The 14z-3 spark thunks remain staged at 99 and are now BELIEVED
UNNECESSARY: the "sword-arc effect object" was a red herring (it's the
generic hit starburst, correct on our build). Delete the rows once
round-27 confirms the swing looks complete; the sword's own +0x18 tile
bank comes from Donovan's ported code (correct 0x4000 already).

Open items, in maintainer priority order:
1. SWORD CONFIRMED (round 27) — blocker closed. Leftovers, non-blocking:
   blade palette (red/grey vs native silver — blink family), 6HP hitbox
   worry (oracle HP matched; a hitbox A/B replay would settle it).
1b. Victor-shock body garble on Donovan (rounds 27+28 = ONE defect;
   14z-6's stale-bucket model was wrong, 14z-7's fix was a phantom —
   both post-mortems in STATE/GOTCHAS): the victim held-pose cursor
   enters Donovan's sequence one jump-node off (opposite node order vs
   native; body pieces draw ~0x20-adjacent band tiles). Entry is
   computed by the reaction/state machinery, NOT the anim-number
   tables. START AT: the seq_set path (vsavj 0x2AD94, +0x14E state
   machine) and the hold-reaction's per-char seq record for slot 0x0F.
   Probes: replay pair 33_victor_6hp (the user's exact repro), OBJ
   pairing method, tap_writes. Acceptance: pixel A/B on replay 33
   BOTH zap and between-zap frames, fix-on vs fix-off.
2. Palette family (non-blocker): win-quote + HUD mini-portrait rows'
   true consumer still undecoded. Start from a palette-RAM write trace
   on the quote screen (rows 0x16-0x1F), NOT from the uploader tables
   (三 sites poked, none feed the visible rows).
3. Wrong-conviction cleanups: grab rows (stage 99) isolated re-test;
   0x248D80 zone attribution re-derivation.
4. 27 oracle re-freeze (throw connects at 3050/3650).
5. M2b select-screen portrait/name + attract palette (task #18).

Tools/infra current: [[data_port]], [[site_thunk]] (per-row stage),
patched_clone reconciliation kind, tap_writes.lua (notifier-hardened,
STACKLOG), pixel probes (SNAP_FRAMES), gates: test_don_sword.sh new.
