# NEXT SESSION — orientation (rewritten at the 14z-173 CLOSE, 2026-09-21)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## M19 IS STILL FROZEN AND STILL NOT RELEASED — the tree is at `build/m3b_merged27`

No shipped ROM byte moved at 14z-173. What DID move is everything around the romset:
the release package, the launcher, the emulator binary and the player documentation.
The romset itself is untouched, so every fingerprint, expectation set and registry row
stands.

## START HERE

1. **THE APPLIER PAGE — slices A2-A6, and nothing blocks it.** The plan is
   `docs/project/applier_app_scope.md`; all three of its open questions were ruled at
   14z-173 (a local file in the asset, one page per release, a browser page is
   acceptable). Slice **A1 is already landed and gated** — `tools/applier/vcdiff.mjs`
   decodes all 20 shipped patches to the manifest's exact sha1, locked by
   `tests/test_applier_vcdiff.sh`. What remains is the page itself, its refusals (which
   are the deliverable — see #146's lesson), the optional-BIOS choice, and the
   byte-identity contract against `apply_release.py`. §3 of the scope names which of its
   feasibility figures are GATED and which were measured under node and still need a
   real browser.
2. **#146 — the READMEs are rewritten but the maintainer has not read them.** They are
   generated, so read `release/merged-m19/fbneo/README.md`. The brief was theirs: *"it
   must have felt clear to the expert who wrote them … the user is usually not a
   developer, and basically never on the project."* Do not close it on our own say-so.
3. **#144 — no longer a mystery, and the decision is a spend.** macOS blocks the
   binaries by design; right-click > Open does NOT get past it (withdrawn everywhere);
   "Open Anyway" works but is PER FILE (MAME: 2 files, 2 approvals, measured), and patch
   0003 took the FBNeo bundle from 24 files to 4 — the matching approval counts are
   inferred from that one data point, not exercised. Notarization is ruled OUT until the community justifies it. The ticket is
   arguably closeable as *mitigated, not eliminated* — the maintainer's call, because
   it means accepting four System Settings clicks.
4. **A LIVE PROBLEM THE CLOSE SURFACED:** `merged-m18` is the CURRENTLY PUBLISHED
   release and its README and `BINARY.txt` still tell macOS players to right-click >
   Open, which is measured false. Anyone downloading today is misinformed. Not rewritten
   (a published release is history, and its GitHub assets would still differ) — so it is
   either a note on the release page or a reason to bring the M19 release forward.

## ALSO OPEN (carried)

- **#145 Windows binaries** — untouched by ruling (macOS first). Note that patch 0003
  drops the SDL2_image link on ALL platforms, so the next Windows build shrinks that
  bundle from **31 files** for free. That does not fix "fails to load", which is still
  unreproduced.
- **No Windows launcher.** `PLAY.command` is macOS/Linux; Windows needs its own.
- **#161** (Phobos's +1 damage), **#169** (`pyron_3`'s Galactic Throw), and the #136
  tickets **#157 / #159 / #163** — all untouched this sitting, all still the
  maintainer's to schedule.

## TRAPS PAID THIS SITTING (14z-173)

1. **An ad-hoc rig's defect is not the subject's defect — this cost four measurements.**
   A relative `ROMDIR` that loaded six members short looked like CRC hash-shadowing; a
   hand-rolled `bundle_dylibs.py` call missing `--extra` looked like our bundler
   under-collecting (it does not — `extra_sdl3_args` already handles it); comparing two
   logs while one was still being written looked like a patch changing behaviour. Build
   the rig the way the project builds it, or attribute the result to the rig first.
2. **`sh -n` validates syntax, not intent.** A rewritten string produced `\"\\"`, which
   closes the shell string and leaves `<name>` as an input redirection. It parsed
   cleanly and broke the build. Run the thing, or at least `CHECK=1` it.
3. **A count is a better check than a script's progress output.** A gate edit silently
   never applied because its script aborted on an earlier assertion; the tell was six
   files staged against five reported changed.
4. **Grepping for a phrase cannot tell advice from its withdrawal.** Checking which
   records still recommended right-click > Open matched the corrected text too, because
   the correction names the thing it withdraws. Grep for the recommendation's wording.
5. **Internal numbering is not shared language.** "Patch 0003" meant nothing to the
   maintainer and stalled a decision until it was restated as what it does. The same
   failure #146 is about.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]).
