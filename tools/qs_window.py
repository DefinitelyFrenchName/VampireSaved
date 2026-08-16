#!/usr/bin/env python3
"""qs_window.py — THE QSOUND SAMPLE-WINDOW ENDPOINT LAW, in one place
(14z-93, GitHub #82).

PACKING LAW #3: a QSound sample record's `end` offset is played and looped
**INCLUSIVE**. Two independent proofs:

1. **Field width.** Native records end at `0xFFFF`. An end-exclusive
   reading cannot express a window running to the top of a bank, so the
   hardware's own data says inclusive.
2. **The sword-plant beep (14z-87b).** `build_qs_songs.py` originally
   COPIED each packed sample end-exclusive. That left every packed
   sample's last *played* byte holding the NEXT blob's first byte — for a
   voice whose loop tail is silence, one foreign byte is a ~1.8kHz impulse
   train sustained to keyoff. Audible on rec 0x3C8 / Donovan 0x705 at
   every plant, with two more contaminated records in the census.

**WHY THIS MODULE EXISTS RATHER THAN THREE COPIES OF `+ 1`.** The builder
was corrected at 14z-87b; `audit_qs_voice_batch.py` and
`check_qs_voice_batch.py` were not, and their comments went on justifying
the exclusive slice with the superseded pre-14z-87b measurement. The tree
therefore contradicted itself in writing for six sessions, and the byte
that the exclusive reading omits is EXACTLY the byte that caused the beep —
so corruption confined to it passed every batch check. A shared law with a
ground-truth test is the fix that cannot drift back apart.

**THE `+ 1` IS ON THE ABSOLUTE INDEX.** `end` is a 16-bit in-bank offset
and may legitimately be `0xFFFF`; the inclusive window then finishes exactly
at the bank boundary. Callers pass absolute image offsets, so this is a
plain slice bound, never a bank-crossing hazard.

Bounds are CHECKED, never clamped: a record whose window leaves the image is
malformed, and silently returning a short slice would compare fewer bytes
than the DSP plays — which is the same class of defect as the exclusive
slice this module replaces.
"""


def length(lo, hi_inclusive):
    """Number of bytes the DSP plays for this window."""
    return hi_inclusive - lo + 1


def window(img, lo, hi_inclusive):
    """Bytes of the window, endpoint INCLUSIVE. Raises on out-of-range."""
    end = hi_inclusive + 1
    if not (0 <= lo <= end <= len(img)):
        raise ValueError(
            "QSound window %#x-%#x (inclusive) leaves the %#x-byte image — "
            "a malformed record, not a short read" % (lo, hi_inclusive, len(img)))
    return img[lo:end]


def try_window(img, lo, hi_inclusive):
    """As window(), but returns b'' instead of raising.

    For callers that PROBE several candidate banks and expect misses (the
    keyon signature walk tries both `bank` and `bank | 0x80`).
    """
    try:
        return window(img, lo, hi_inclusive)
    except ValueError:
        return b''
