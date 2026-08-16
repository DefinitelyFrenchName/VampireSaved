#!/usr/bin/env python3
"""s4_thresholds.py — THE RATIFIED CLAUDE.md §4 THRESHOLDS, in one place
(14z-93, GitHub #44).

Two numbers govern every non-exact legacy comparison class:

    FLICKER_MAX = 2    a divergent run this short or shorter is a FLICKER
                       frame (§4 v2, "isolated <=2-frame divergences")
    RECONVERGE  = 60   identical frames required after the last divergence
                       (§4 v2, the non-propagation proof; see also v5, which
                       rules this figure INTRA-MECHANISM — it governs the
                       re-convergence TAIL and does not bind across the gap
                       between two separately attributed mechanisms)

They were declared FOUR times — `describe_masked_shape.py`,
`compare_composite.py`, `compare_flicker.py`, `compare_window.py` — with a
comment saying they "must stay in step" and nothing asserting it.
`describe_masked_shape.py` exists specifically to give the classifier "one
set of thresholds, one place to correct"; it achieved that for the heredoc
it replaced and left the comparators as three more places.

**THE FAILURE THAT MOTIVATES THIS IS SILENT AND WELL-SHAPED.** Change
`FLICKER_MAX` to 3 in `compare_composite.py` after a ruling, and
`describe_masked_shape.py` keeps proposing expectation lines that classify a
3-frame run as a flicker. The proposed line is pasted verbatim into a
`.masked` file — which is exactly what that tool is FOR — and the composite
checker then rejects it as a flicker/window mismatch. The tool whose whole
purpose is "propose a line that drops in verbatim" proposes a line that
cannot pass.

These are RATIFIED values. Changing one is a §4 amendment and a maintainer
decision, not a tuning knob — which is the other reason they belong in a
file that says so rather than in four argparse defaults.
"""

FLICKER_MAX = 2
RECONVERGE = 60
