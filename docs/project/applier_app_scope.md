# THE APPLIER APP — scope, before the work

> **STATUS (written 14z-173, 2026-09-20): THE PLAN BEFORE THE WORK — nothing has
> shipped.** It is **item 5** of the deliverables order ruled the same day
> (`DECISIONS_HISTORY.md` "Ruled 2026-09-20 (14z-173) — THE DELIVERABLES"), so the
> standalone set (landed), the launcher (landed), the per-OS binary tickets #144/#145
> and the README pass #146 come first. **One slice is nonetheless already proven**:
> A1's VCDIFF port decodes all 20 shipped patches to the manifest's exact SHA-1, and
> every other capability the page needs was measured native rather than assumed (§3).
> **Three things are OPEN for the maintainer** and none of them is mine to settle: where
> the page lives, whether it ships per release or once, and whether a browser page is
> acceptable at all for players handing over ROM files (§6).

**Why this document exists:** the same reason `harness_scope.md` and
`living_docs_scope.md` do. This is a backlog direction the maintainer ordered, it is
big enough that starting it blind would waste a sitting, and the form was left to me
(*"Web, OS-agnostic or one per OS, I don't really care"*), so the choice and its
evidence belong in writing before any of it ships.

**The ask (maintainer, 2026-09-20), verbatim:**

> *"about how to create vsavjw, the issue is it's asking people to install python and
> run the commands and all. Can't we package a nice tiny app (Web, OS-agnostic or one
> per OS, I don't really care) that is self-supporting executable-wise and just asks
> the roms and provides vsavjw.zip from it? Because the developers won't care but the
> immense majority of the users will."*

It is **item 5** of the order ruled the same day (`DECISIONS_HISTORY.md` "Ruled
2026-09-20 (14z-173) — THE DELIVERABLES"): the standalone set, the launcher, the
per-OS binary tickets and the README pass come first.

## 2. THE RECOMMENDATION: ONE STATIC HTML PAGE, RUNNING ENTIRELY IN THE BROWSER

Not a per-OS executable. The reasoning is not aesthetic:

- **It dodges the problem we are already stuck on.** #144 and #145 exist because an
  unsigned binary is hard to get an OS to run. Shipping a *second* unsigned binary —
  one that asks for the player's ROM files — doubles that problem and asks for more
  trust, not less. A web page needs no signature, no notarisation, no SmartScreen
  exception and no install.
- **It is genuinely OS-agnostic**, which is what the maintainer asked for first.
- **It needs no toolchain from us and no Python from them**, which is the whole
  complaint.

**THE HARD CONSTRAINT, and it is a rule-7 matter: the page must be provably
client-side.** No upload, no telemetry, no network call after load. The player's ROMs
are commercial dumps; a page that posted them anywhere would be a copyright problem
and a betrayal of the reason this project ships deltas instead of bytes. It must also
carry the same per-member SHA-1 verification `apply_release.py` does, or it is a worse
applier wearing a nicer coat.

## 3. FEASIBILITY — MEASURED, NOT ASSUMED

Every capability the page needs exists natively, so the dependency count is **zero**:

| need | mechanism | evidence |
|---|---|---|
| read the player's dumps | `<input type="file" multiple>` -> `ArrayBuffer` | standard |
| read zip members (DEFLATE) | `DecompressionStream("deflate-raw")` | round-tripped 200,000 bytes byte-identical |
| write `vsavjw.zip` (DEFLATE) | `CompressionStream("deflate-raw")` | same test |
| SHA-1 every member | `crypto.subtle.digest("SHA-1", …)` | agrees with Python's digest on the same input |
| decode the 20 patches | **a JS port of `vcdiff_decode`** | **20 of 20 patches decoded to the manifest's exact SHA-1, 0.2 s** |
| hand over the result | `Blob` + download link | standard |

**The port is the only real work, and it is done and proven** (the measurement above,
against the shipped `release/merged-m19` patches). Everything else is wiring.

**WHICH OF THOSE ROWS IS GATED, and which is not.** Only the decoder is:
`tests/test_applier_vcdiff.sh` re-runs it against every shipped patch on every static
tier. The `deflate-raw` round trip and the `crypto.subtle` SHA-1 agreement were measured
**under node's implementation of those same web standards, not in a browser**, and they
are NOT gated — a gate there would be testing node, not the thing the page runs on. Treat
them as what they are: strong evidence that the APIs do what the plan needs, to be
confirmed in a real browser when slice A2 is written. That confirmation is part of A2, not
something this document has already banked.

The shape of the job, from the M19 manifest: a **97.0 MB** source blob rebuilt from 51
members of 3 zips; **20** patches totalling 2.62 MB of VCDIFF; 12 pristine copies; **32**
output members, 73.7 MB uncompressed; **83** SHA-1 verifications; largest member 4.2 MB.
Naive peak memory is ~171 MB, which a browser tab holds, but see the slices.

## 4. SLICES

- **A1 — the decoder, extracted and locked.** The JS port as one module, plus the
  fidelity test that decodes every shipped patch and compares against the manifest's
  SHA-1. This is the slice that makes the rest safe, and it is the one already
  measured.
- **A2 — the page, offline.** File pickers, the blob rebuild, the 83 verifications, the
  zip writer, the download. Streamed rather than naive where it costs nothing, to keep
  peak memory near the 97 MB blob rather than 171 MB.
- **A3 — the refusals, which are the deliverable.** Every message
  `apply_release.py` produces must have a page equivalent naming the same thing: a
  wrong or modified dump **by member name**, a missing dump, a corrupted patch, a
  rebuilt member that does not match. A page that fails vaguely is worse than a
  command line that fails precisely.
- **A4 — the choice the applier now has:** the optional QSound BIOS member
  (`--no-qsound-bios`), which the page must offer with the same guidance the READMEs
  give — default for emulators, off for MiSTer.
- **A5 — THE FIDELITY CONTRACT.** The page's output must be **byte-identical to
  `apply_release.py`'s** for the same dumps, member for member, and hash to the
  manifest's `applied_set_key`. This is the acceptance, and it is the same shape the
  `bbh` F-series uses: not "it looks right", but "it equals the tool of record".
- **A6 — where it lives.** Undecided; see below.

## 5. NOT IN SCOPE

- Replacing `apply_release.py`. It stays the tool of record, the thing the gates run,
  and the route for anyone who prefers a command line. The page is an alternative
  front end to the same manifest, never a second definition of the romset.
- Building or shipping the emulators. That is #144/#145.
- Anything that makes the page a prerequisite: a release must remain usable with
  Python alone.

## 6. OPEN — FOR THE MAINTAINER

1. **Where does it live?** A release asset is a zip the player must unzip and open
   locally (works, no hosting, but `file://` has quirks); GitHub Pages on this repo is
   one URL that always matches the latest release (but is a hosted surface we then
   maintain, and must be shown to be doing no upload). A local file is the more
   conservative default and my recommendation unless you want the URL.
2. **Does it ship per release, or once?** Pinned to a release's manifest is simpler to
   verify; a generic page that reads any release's `manifest.json` is one artifact
   forever but must then tolerate manifests it has not seen.
3. **Is a browser page acceptable at all** for players who will be asked to hand a
   local page their ROM files? The trust story is better than an unsigned binary's,
   but it is still a thing to say out loud in the README.

## 7. Provenance

Every figure here was measured on 2026-09-20 (14z-173) against
`release/merged-m19` and its manifest; the decoder fidelity run and the
`deflate-raw`/SHA-1 checks are recorded in STATE 14z-173.
