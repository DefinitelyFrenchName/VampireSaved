# `tools/applier/` — slice A1 of the applier app

The plan is `docs/project/applier_app_scope.md`. **Only the decoder is here**, because
it is the only part that was hard and it is now proven; the page itself (slices A2-A6)
is not written and three of its questions are still the maintainer's.

- **`vcdiff.mjs`** — a JS port of `tools/apply_release.py`'s `vcdiff_decode`: the same
  RFC 3284 subset, the same refusals (secondary compression, a custom code table and
  per-section compression are all rejected, exactly as the packager guarantees they
  never occur). Pure ES module, no dependencies, runs in a browser or under node.

Ground truth: **`tests/test_applier_vcdiff.sh`** decodes every patch of the shipped
release with this module and requires the manifest's exact size and SHA-1 for each —
the same acceptance `apply_release.py` is held to. It is not "the port looks right", it
is "the port equals the tool of record on the bytes we actually ship".

Nothing here is shipped to players yet and nothing depends on it: `apply_release.py`
remains the tool of record and the only applier a release carries.
