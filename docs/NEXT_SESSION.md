# NEXT SESSION — orientation (rewritten at the 14z-131 CLOSE, 2026-09-04)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **START HERE. NOTHING IS HALF-DONE AND NOTHING IS OWED.** M13 is frozen,
> ## registered, tagged and pushed; the emulator tier was adjudicated 131/1
> ## with that red now green; static is **130/0/0/0 strict**. No ritual step is
> ## outstanding and there is no red anywhere.
> ##
> ## # THE TWO THINGS THE MAINTAINER HAS NOT YET HAD
> ##
> ## **(1) NO FIELD TEST OF M13, AND NO RELEASE.** M13 has never been to the
> ## board. Its predecessor M12 was field-verified GREEN twice; M13 adds only
> ## the boot name screen (VAMPIRE SAVED, Japan entry) and the M13 glyph tiles
> ## on top of it, and the member delta is exactly three files. A bundle is the
> ## maintainer's call, and so is the release — deliberately held back.
> ##
> ## **(2) THE +/-1 DAMAGE RESIDUE — KNOWLEDGE, NOT A BUG.** 5 of 54
> ## victim/throw cells on Phobos's throws differ by exactly one point of total
> ## damage from native vsav2 (`0x10` +1 on all three throws, `0x13` -1 on all
> ## three, `0x0A` -1 on Circuit Scrapper only). **RULED WITHIN TOLERANCE
> ## (maintainer, 2026-09-04)** — *"interesting to root-cause it to deepen our
> ## understanding of the engines though so let's keep that open for a future
> ## session."* It is FROZEN in `audit_tenant_throw_geometry` with its exact
> ## deltas, so a red there means THE RESIDUE MOVED, not that damage is broken.
> ## **Start from the eliminations, do not re-derive them** (STATE has them in
> ## full): starting HP is 288 on both legs for every victim; it is TOTAL
> ## damage, not a split artifact; `bank_map` models no per-character defence
> ## table; the sign is stable per victim across all three throws.
> ## **Cheapest first step, the discriminator:** `0x0A` is a LEGACY victim
> ## (ours is VS's Sasquatch, native is VS2's), so if Capcom retuned him
> ## between the games that cell is CROSS-GENERATION and the residue splits
> ## into two unrelated causes. Then PC-attribute the writes to `$FF8850` with
> ## `tap_writes.lua`'s `REGLOG`.
> ##
> ## # WHAT THIS SESSION LEFT BEHIND THAT CHANGES HOW YOU WORK
> ##
> ## **`docs/project/gate_scoping_method.md` — READ IT BEFORE BUILDING ANY
> ## COMPARISON GATE.** Eight rules, [VSP-167]..[VSP-174], distilled into the
> ## `vampire-saved-port` skill. Every one is something that went wrong in
> ## 14z-131 first, which is the only reason to trust them: the reference is
> ## the SOURCE GAME and a second leg is an INSTRUMENT CHECK, not a baseline;
> ## check the mechanism can PRODUCE the observable and exclude
> ## cross-generation confounds (a legacy character's art differs between VS
> ## and VS2 — pixels are never evidence about the port); compare ORDERED
> ## structure and REPORT timing; refuse to judge a leg that did not produce
> ## the event and assert the RESOURCE it consumes; measure the cost of
> ## widening and re-check every constant the narrow version froze; diff a
> ## strengthened gate against what it REPLACED; capture before
> ## characterising; and a divergence on exactly the rows with a special
> ## resolution rule is the RESOLVER.
> ##
> ## # OPERATIONAL, each paid for this session
> ##
> ## * **An ES move with no meter degrades SILENTLY to its normal version** —
> ##   same offsets, same poses, same damage, a healthy-looking run measuring
> ##   the wrong move. Poke the stock and assert it DROPS.
> ## * **`${=var}` is zsh-only.** A gate is `#!/bin/sh`, where a bare `$var`
> ##   DOES word-split; an interactive Bash-tool command is zsh, where it does
> ##   NOT. This fired TWICE in one session — once silently reducing an
> ##   18-victim sweep to a single iteration that still printed a verdict.
> ## * **Time a sweep before arguing about its scope.** "All 18 victims" was
> ##   assumed expensive and measured at 186 s against 27.7 s for one.
> ## * **A gate's own header runtime can be wildly wrong** — this one claimed
> ##   "~12 min" for something that takes 27.7 s. Measure, then write it.
> ##
> ## **IF A DOC IS TOUCHED:** census `--check` + `checkdocshape --no-pending` +
> ## checkdocs + checkskills + `gen_annotations --check` + `gen_gate_index
> ## --check` + `gen_gotchas_index --check` + `doc_anchor_census --check`,
> ## exit statuses captured directly. Regenerate the GENERATED indexes in the
> ## commit that changes what they index, and AFTER the prose.
