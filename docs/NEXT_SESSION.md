# NEXT SESSION — orientation (rewritten at the 14z-130 CLOSE, 2026-09-04)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **START HERE. M13 IS FROZEN, REGISTERED AND TAGGED.** donovan-m19 /
> ## huitzil-m26 / pyron-m20 / merged-m15, mark **M13**, the boot name screen
> ## reading **VAMPIRE SAVED**. Registry rows, `freeze/*` tags, expectation
> ## sets, the 137-file re-point sweep, the pointer-flow baselines and the
> ## MiSTer CRC tail are all done. Static tier **130/0/0/0 strict**.
> ##
> ## # THE TWO THINGS THAT ARE NOT DONE
> ##
> ## **(1) THE EMULATOR-TIER FREEZE SWEEP WAS STILL RUNNING AT THE CLOSE.**
> ## `ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2
> ## tests/run_all_emulator.sh --freeze` — 132 gates at romset cadence, the
> ## scope the 14z-129 ruling makes mandatory at every freeze. Its log is
> ## `<scratch>/emu_m13.log` and it will be GONE (scratch is session-local),
> ## so **re-run it and read the result before anything else** — a freeze whose
> ## emulator tier was never adjudicated is not a finished freeze.
> ## **THE CADENCE QUESTION WAS ASKED AND ANSWERED AT THIS FREEZE: NO.** The
> ## runner dropped the six `bitstream` gates and printed "IS THIS FREEZE
> ## TARGETING MiSTer?". It is not — the `.rbf` has not moved since 14z-108
> ## (seed 18269). What this freeze touched on the MiSTer side is the fork's
> ## CRC CATALOGUE, which follows the ROMSET, and its gate
> ## (`test_mister_mra_map`) is romset-cadence and already GREEN. If a future
> ## freeze moves the bitstream, the answer flips and the re-run is
> ## `--cadence all --lane mister`.
> ##
> ## Expect the sweep to
> ## be mostly green: the four `run_suite` tracks were 8/8 and every
> ## expectation set is a pure carry, so anything red is far more likely to be
> ## an instrument that rotted around a healthy artifact (the 14z-129 lesson)
> ## than a defect in M13.
> ##
> ## **(2) NO RELEASE, and NO FIELD TEST YET.** M13 has not been to the board.
> ## The M12 predecessor was field-verified GREEN twice; M13 changes only the
> ## boot name screen and the M13 glyph tiles on top of it. A bundle is the
> ## maintainer's call.
> ##
> ## # WHAT M13 ACTUALLY CHANGED, in one line each
> ##
> ## * **The boot name screen reads VAMPIRE SAVED** (Japan entry only) — three
> ##   `aux_poke poke16` at `PRG:0x01C822/24/26`, in member **`vm3j.03d`**
> ##   (STATE 14z-127 said `vm3j.10b`; corrected 14z-130 by member diff).
> ## * **The `gap_be27a` bank-map correction**, folded in by ruling and
> ##   **BYTE-NEUTRAL on all five tracks by rebuild**.
> ## * Member delta merged-m14 -> merged-m15 is exactly three files:
> ##   `vm3j.03d` + `vsw.33m` + `vsw.37m`.
> ## * **Every expectation set is a PURE CARRY** — M13 is RAM-identical to M12
> ##   across the whole replay corpus, measured twice per track.
> ##
> ## # THE ONE NEW DECISION WAITING (STATE "Decisions pending")
> ##
> ## **PYRON'S CAPTURE-KEYFRAME ATTACKER ROW `0x11` IS NOT PORTED** — when
> ## Pyron throws, the capture poses are DEMITRI's. Not a regression; it has
> ## been so since the #104 work, and donovan.toml records it as "the recorded
> ## Pyron-as-attacker observation". It surfaced because the corrected bank-map
> ## row made the generator WANT to fix it (`0x0BE2BE <- 0x004af226`), and the
> ## ownership claim suppressed it so the freeze stayed byte-neutral.
> ## **Recommendation: measure before deciding** — a Pyron throw beside a
> ## native vs2 Pyron throw ([VSP-123] reaches the native leg with an ordinary
> ## poke). Nobody has ever looked at whether it is visibly wrong.
> ##
> ## # THE TRAPS THIS SESSION PAID FOR — read before the next freeze
> ##
> ## * **THE RE-POINT SWEEP REWRITES HISTORY.** It is cut 2 of the gotcha "A
> ##   RE-POINT SWEEP STAMP ON A TOML SECTION HEADER…", paid at 14z-119 and hit
> ##   again here: the blind sweep rewrote the 14z-119 patch_notes entry to
> ##   claim donovan-m18 lives in `build/don_m19`. **Follow that entry's rule
> ##   (2) every time**: after the sweep, list the comment-line hits and read
> ##   each one. 13 dated records had to be restored — one of them in a
> ##   registry row written the same hour.
> ## * **`run_suite --freeze` AGAINST A BATTERY-SCOPED SET MANUFACTURES
> ##   EXPECTATIONS.** The stock set carries 14 authored `.masked` specs and no
> ##   `.sha1` at all; a full-corpus `--freeze` wrote 79. Diff every new set
> ##   against its predecessor before committing — "SUITE GREEN" does not tell
> ##   you what the freeze CREATED.
> ## * **A gate can be the only thing that can see a defect.** The merged
> ##   ownership bug was invisible to the merged BUILD (its pinned extracts
> ##   predate the row) and visible only to `test_merged_inputs` section 2,
> ##   which regenerates them.
> ##
> ## **IF A DOC IS TOUCHED:** census `--check` + `checkdocshape --no-pending` +
> ## checkdocs + checkskills + `gen_annotations --check` + `gen_gate_index
> ## --check` + `gen_gotchas_index --check` + `doc_anchor_census --check`,
> ## exit statuses captured directly. Regenerate the GENERATED indexes in the
> ## commit that changes what they index, and AFTER the prose.
