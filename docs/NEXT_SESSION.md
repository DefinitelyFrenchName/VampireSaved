# NEXT SESSION — orientation (rewritten at the 14z-174 CLOSE, 2026-09-21)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## M19 IS STILL FROZEN AND STILL NOT RELEASED — the tree is at `build/m3b_merged27`

No shipped ROM byte moved at 14z-174 either. The release was RE-PACKAGED (no manifest
and no patch moved — only the READMEs, `apply_release.py` and the new browser applier),
so every fingerprint, expectation set and registry row still stands.

**What changed is that the release's own blocker list is now empty but for #145**, and
the maintainer has ruled that #145 does not have to block it: *"it's acceptable not to
have all the environments available as long as we have sources, MiSTer core, and an
easy way to produce the wide patched rom."* All three of those exist.

## START HERE

1. **RELEASE M19. This is the decision the maintainer has already leaned on** — *"we
   absolutely should aim to bring M19 forward, not try to patch M18's release docs"* —
   and it is now the largest open item. It has not been started because publishing is
   outward-facing and wanted their go-ahead. What it costs, from the ritual
   (`vampire-saved-port` D.4, `docs/project/release_format.md`):
   - the **freeze-cadence static tier** with `ROMDIR` (`--cadence freeze`), then the
     **release-cadence** one — the only runs that exercise those gates;
   - the **emulator tier at release scope**: `--scope all --lane all --strict
     --controls`, **measured 5 h 37 min** at `--jobs 4` on this MacBook (14z-153). Run
     it DETACHED and poll the PID; never beside other heavy work;
   - then `tools/upload_release_assets.sh freeze/merged-m19 --prune`, which publishes
     the assets and deletes M18's.
   **The live problem this fixes:** `merged-m18` is what the public can download today,
   and its README and `BINARY.txt` still give the right-click > Open advice that 14z-173
   measured false. Every day M19 is unreleased, that is what a new player reads.
2. **#145 — Windows binaries "fail to load", still unreproduced, and no longer a
   blocker.** Worth an hour before or after the release: patch 0003 drops the SDL2_image
   link on Windows too, taking that bundle from **31 files** to a handful at the next
   build, which may or may not be the same problem.
3. **No Windows launcher.** `PLAY.command` is macOS/Linux; Windows players follow the
   README by hand. The browser applier now covers step 1 on every OS, so what is left
   for Windows is only steps 2 and 3.
4. **#170 (new) — notarize the macOS binaries.** PARKED on community demand by the
   maintainer's own condition; split out of #144 so closing that one did not bury it.
5. **#161** (Phobos's +1 damage), **#169** (`pyron_3`'s Galactic Throw), and the #136
   tickets **#157 / #159 / #163** — all untouched again, all still the maintainer's to
   schedule.

## THE ONE THING A HUMAN SHOULD DO BEFORE THE RELEASE

**Open `release/merged-m19/fbneo/apply_release.html` by double-clicking it, and build a
romset with it.** Two reasons, both named in `applier_app_scope.md` §3 rather than
glossed: **no human has ever used the page** (only a script has driven it), and
**WebKit/Safari is UNMEASURED** — which is the engine a double-clicked `.html` opens on
macOS by default. Chromium is gated, Gecko was measured by hand on a capability probe.
The page names any capability it cannot find rather than failing obscurely, but that is
a mitigation, not a measurement.

## TRAPS PAID THIS SITTING (14z-174)

1. **Measure the platform BEFORE designing for it.** The scope document's central
   assumption — that the page could read the `manifest.json` and `patches/` beside it —
   is false in every browser: `fetch`, XHR and cross-file `import` are all refused from
   `file://`. A 20-minute probe before any code was written is why that cost nothing.
2. **One buffer is not a corpus.** `CompressionStream` and Python's zlib produced a
   byte-identical deflate stream on one 200 KB fixture, which would have supported a
   whole-zip byte-identity claim. On the **32 real members they disagree on all 32**.
   The fixture agreed by being one chunk; streaming flush boundaries are the mechanism.
3. **A control that does not fire is a bug report about the control.** `no-member-check`
   was DEAD on its first run: removing the rebuilt-member check does not let a corrupted
   patch through, because VCDIFF's own adler32 catches it first. Re-aim the control at
   the perturbation only that check can see (here, a tampered manifest) — do not widen
   the gate until the control passes.
4. **A strict checker with no exemptions is worth adapting the code for.** The
   generator's self-containment scan refused two of my own pages — a comment using the
   literal token, and a `href="${url}"` in a template literal. Both were fixed rather
   than exempted: an exemption is exactly where a real network call would hide.
5. **A guarantee the browser enforces beats a list you maintain — and it will break
   your harness, which is the point.** "No network primitive" was a denylist of seven
   names with one control, and the page itself carried a URL assignment the scan could
   not see. The fix was a Content-Security-Policy, not a longer list. It immediately
   killed the browser gate's driver (which lived inside the document and could no longer
   fetch), and the right response was to move the driver OUT into a page that iframes the
   shipped file — never to weaken the policy so the test could pass.
6. **Headless Chrome's `--virtual-time-budget` is spent by `setTimeout`.** A polling
   loop exhausts the budget and the DOM dumps mid-run; use `MutationObserver`. And do
   not `fetch` a `blob:` URL in a driver — the pending fetch truncates the dump.

7. **An iframe's `contentDocument` is `about:blank` until the real navigation lands —
   and that placeholder already reports `readyState === "complete"`.** Resolving on it
   observes a document the browser is about to discard, and every later wait hangs
   forever. Wait for the `load` event, or check the frame's own URL.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]).
